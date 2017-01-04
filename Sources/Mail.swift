//
//  Mail.swift
//  Hedwig
//
//  Created by Wei Wang on 2016/12/31.
//
//

import Foundation
import AddressParser

enum MailError: Error {
    case noSender
    case noRecipient
}

struct Mail {
    let from: NameAddressPair
    let to: [NameAddressPair]?
    let cc: [NameAddressPair]?
    let bcc: [NameAddressPair]?
    let subject: String?
    let text: String
    let attachments: [Attachment]?
    let additionalHeaders: [String: String]?
    
    let boundary = UUID().uuidString

    fileprivate let messageId = UUID().uuidString
    fileprivate let date = Date()
    
    init(text: String,
         from: String,
         to: String? = nil,
         cc: String? = nil,
         bcc: String? = nil,
         subject: String?,
         attachments: [Attachment]? = nil,
         additionalHeaders: [String: String]? = nil)
        throws
    {
        guard let fromAddress = from.parsedAddresses.last else {
            throw MailError.noSender
        }
        self.from = fromAddress
        
        guard let _ = to ?? cc ?? bcc else {
            throw MailError.noRecipient
        }
        self.to = to?.parsedAddresses
        self.cc = cc?.parsedAddresses
        self.bcc = bcc?.parsedAddresses
        
        self.text = text
        self.subject = subject
        self.attachments = attachments
        self.additionalHeaders = additionalHeaders
    }
}

extension Mail {
    private var headers: [String: String] {
        var fields = [String: String]()
        fields["Message-Id"] = messageId
        fields["Date"] = date.smtpFormatted
        fields["From"] = from.mime
    
        if let to = to {
            fields["To"] = to.map { $0.mime }.joined(separator: ", ")
        }
    
        if let cc = cc {
            fields["Cc"] = cc.map { $0.mime }.joined(separator: ", ")
        }
        
        if let bcc = bcc {
            fields["Bcc"] = bcc.map { $0.mime }.joined(separator: ", ")
        }
        
        fields["Subject"] = (subject ?? "").mimeEncoded ?? ""
        fields["MIME-Version"] = "1.0 (Hedwig)"
        
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                fields[key] = value
            }
        }

        return fields
    }
    
    var headersString: String {
        return headers.map { (key, value) in
            return "\(key.uppercased()): \(value)"
        }.joined(separator: CRLF)
    }
}

struct Attachment {
    enum AttachmentType {
        case filePath(String)
        case html(String)
    }
    
    let type: AttachmentType
    let mimeType: String? = nil
    let name: String? = nil
    let method: String?
    let charSet: String?
    let alternative = false
    let inline = false
    let headers: [String: String]? = nil
    let related: [Attachment]? = nil
}

struct NameAddressPair {
    let name: String
    let address: String
    
    var mime: String {
        if name.isEmpty {
            return address
        }
        
        if let nameEncoded = name.mimeEncoded {
            return "\(nameEncoded) <\(address)>"
        } else {
            return address
        }
    }
}

extension Address {
    var allMails: [NameAddressPair] {
        var result = [NameAddressPair]()
        switch entry {
        case .mail(let address):
            result.append(NameAddressPair(name: name, address: address))
        case .group(let addresses):
            let converted = addresses.flatMap { return $0.allMails }
            result.append(contentsOf: converted)
        }
        return result
    }
}

extension String {
    var parsedAddresses: [NameAddressPair] {
        return AddressParser.parse(self).flatMap { $0.allMails }
    }
}

extension String {
    // A simple but maybe not fully compatible with RFC 2047
    // https://tools.ietf.org/html/rfc2047
    var mimeEncoded: String? {
        guard let encoded = addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        let quoted = encoded
            .replacingOccurrences(of: "%20", with: "_")
            .replacingOccurrences(of: ",", with: "%2C")
            .replacingOccurrences(of: "%", with: "=")
        return "=?UTF-8?Q?\(quoted)?="
    }
}

extension DateFormatter {
    static let smtpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en-US")
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
        return formatter
    }()
}

extension Date {
    var smtpFormatted: String {
        return DateFormatter.smtpDateFormatter.string(from: self)
    }
}
