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
    let text: String
    let from: NameAddressPair
    let to: [NameAddressPair]?
    let cc: [NameAddressPair]?
    let bcc: [NameAddressPair]?
    let subject: String?
    let attachment: [Attachment]?
    let additionalHeaders: [String: String]?
    
    init(text: String, from: String, to: String? = nil, cc: String? = nil,
         bcc: String? = nil, subject: String?, attachment: [Attachment]? = nil,
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
        self.attachment = attachment
        self.additionalHeaders = additionalHeaders
    }
    
    var headers: [String: String] {
        return [:]
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


typealias NameAddressPair = (name: String, address: String)
extension Address {
    var allMails: [NameAddressPair] {
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
    var parsedAddresses: [NameAddressPair] {
        let a = AddressParser.parse(self).flatMap { $0.allMails }
        return a
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
