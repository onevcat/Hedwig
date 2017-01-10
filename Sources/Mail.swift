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
    let to: [NameAddressPair]
    let cc: [NameAddressPair]?
    let bcc: [NameAddressPair]?
    let subject: String
    let text: String
    let attachments: [Attachment]
    let additionalHeaders: [String: String]

    let alternative: Attachment?
    
    let messageId = UUID().uuidString
    let date = Date()
    
    init(text: String,
         from: String,
         to: String,
         cc: String? = nil,
         bcc: String? = nil,
         subject: String = "",
         attachments: [Attachment]? = nil,
         additionalHeaders: [String: String] = [:])
        throws
    {
        guard let fromAddress = from.parsedAddresses.last else {
            throw MailError.noSender
        }
        self.from = fromAddress

        self.to = to.parsedAddresses
        self.cc = cc?.parsedAddresses
        self.bcc = bcc?.parsedAddresses
        
        let noCc = self.cc?.isEmpty ?? true
        let noBcc = self.bcc?.isEmpty ?? true
        
        if self.to.isEmpty && noCc && noBcc {
            throw MailError.noRecipient
        }
        
        
        self.text = text
        self.subject = subject

        if let attachments = attachments {
            let result = attachments.takeLast { $0.isAlternative }
            self.alternative = result.0
            self.attachments = result.1
        } else {
            self.alternative = nil
            self.attachments = []
        }
    
        self.additionalHeaders = additionalHeaders
    }
}

extension Mail {
    private var headers: [String: String] {
        var fields = [String: String]()
        fields["MESSAGE-ID"] = messageId
        fields["DATE"] = date.smtpFormatted
        fields["FROM"] = from.mime
    
        fields["TO"] = to.map { $0.mime }.joined(separator: ", ")
        
        if let cc = cc {
            fields["CC"] = cc.map { $0.mime }.joined(separator: ", ")
        }
        
        fields["SUBJECT"] = subject.mimeEncoded ?? ""
        fields["MIME-VERSION"] = "1.0 (Hedwig)"
        
        for (key, value) in additionalHeaders {
            fields[key.uppercased()] = value
        }
    
        return fields
    }
    
    var headersString: String {
        return headers.map { (key, value) in
            return "\(key): \(value)"
        }.joined(separator: CRLF)
    }
    
    var hasAttachment: Bool {
        return alternative != nil || !attachments.isEmpty
    }
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

extension Array {
    func takeLast(where condition: (Element) -> Bool) -> (Element?, Array) {
        var index: Int? = nil
        for i in (0 ..< count).reversed() {
            if condition(self[i]) {
                index = i
                break
            }
        }
        
        if let index = index {
            var array = self
            let ele = array.remove(at: index)
            return (ele, array)
        } else {
            return (nil, self)
        }
    }
}
