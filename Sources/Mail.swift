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
    case noRecipient
}

struct Mail {
    let text: String
    let from: String
    let to: String?
    let cc: String?
    let bcc: String?
    let subject: String?
    let attachment: [Attachment]?
    
    init(text: String, from: String, to: String? = nil, cc: String? = nil,
          bcc: String? = nil, subject: String?, attachment: [Attachment]? = nil)
        throws
    {
        self.text = text
        self.from = from.parsedAddress
        
        guard let _ = to ?? cc ?? bcc else {
            throw MailError.noRecipient
        }
        
        self.to = to?.parsedAddress
        self.cc = cc?.parsedAddress
        self.bcc = bcc?.parsedAddress
        
        self.subject = subject
        self.attachment = attachment
    }
}

struct Attachment {
    enum AttachmentType {
        case filePath(String)
        case html(String)
    }
    
    let type: AttachmentType
    let mimeType: String?
    let name: String?
    let method: String?
    let charSet: String?
}

extension Address {
    var allMails: [(name: String, address: String)] {
        var result = [(name: String, address: String)]()
        switch entry {
        case .mail(let address):
            result.append((name, address))
        case .group(let addresses):
            let converted = addresses.flatMap { return $0.allMails }
            result.append(contentsOf: converted)
        }
        return result
    }
}

extension String {
    var parsedAddress: String {
        return AddressParser.parse(self).map { address in
            address.allMails.map { mail in
                mail.name.isEmpty ?
                    mail.address : "\(mail.name.mimeEncoded) <\(mail.address)>"
            }.joined(separator: ", ")
        }.joined(separator: ", ")
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
