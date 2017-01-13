//
//  Mail.swift
//  Hedwig
//
//  Created by Wei Wang on 2016/12/31.
//
//  Copyright (c) 2017 Wei Wang <onev@onevcat.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import AddressParser


/// Possible errors when validating the mail before sending.
///
/// - noSender: The `FROM` field of the mail is not valid or empty.
/// - noRecipient: The `TO`, `CC` and `BCC` fields of the mail is not valid or
///                empty.
public enum MailError: Error {
    /// The `FROM` field of the mail is not valid or empty.
    case noSender
    /// The `TO`, `CC` and `BCC` fields of the mail is not valid or empty.
    case noRecipient
}

/// Represents an email. It contains necessary information like `from`, `to` and
/// `text` with which Hedwig could send it with a connection to some SMTP server.
/// The whole type is immutable. You need to create a mail through the initialzer
/// and then feed it to a `Hedwig` instance to send.
public struct Mail {
    
    /// From name and address.
    public let from: NameAddressPair?
    
    /// To names and addresses.
    public let to: [NameAddressPair]
    
    /// Carbon copy (Cc) names and addresses.
    public let cc: [NameAddressPair]?
    
    /// Blind carbon copy (Bcc) names and addresses.
    public let bcc: [NameAddressPair]?
    
    /// The title of current email.
    public let subject: String
    
    /// The text content of current email.
    public let text: String
    
    /// The attachements contained in the email.
    public let attachments: [Attachment]
    
    /// The additional headers will be presented in the mail header.
    public let additionalHeaders: [String: String]

    /// The alternative attachement. The last alternative attachment in
    /// `attachments` will be the `alternative` attachement of the whole `Mail`.
    public let alternative: Attachment?
    
    /// Message id. It is a UUID string appeneded by `.Hedwig`.
    public let messageId = UUID().uuidString + ".Hedwig"
    
    /// Creating date of the mail.
    public let date = Date()
    
    /// Initilize an email.
    ///
    /// - Parameters:
    ///   - text: The plain text of the mail.
    ///   - from: From name and address.
    ///   - to: To names and addresses.
    ///   - cc: Carbon copy (Cc) names and addresses. Default is `nil`.
    ///   - bcc: Blind carbon copy (Bcc) names and addresses. Default is `nil`.
    ///   - subject: Subject (title) of the email. Default is empty string.
    ///   - attachments: Attachements of the mail.
    ///   - additionalHeaders: Additional headers when sending the mail.
    ///
    /// - Note:
    ///   - The `from`, `to`, `cc` and `bcc` parameters accept a email specified
    ///     string as input. Hedwig will try to parse the string and get email
    ///     addresses. You can find supported string format
    ///     [here](https://github.com/onevcat/AddressParser).
    ///   - If you need to customize the mail header field, pass it with 
    ///     `additionalHeaders`.
    ///
    public init(text: String,
         from: String,
         to: String,
         cc: String? = nil,
         bcc: String? = nil,
         subject: String = "",
         attachments: [Attachment]? = nil,
         additionalHeaders: [String: String] = [:])
    {
        self.from = from.parsedAddresses.last

        self.to = to.parsedAddresses
        self.cc = cc?.parsedAddresses
        self.bcc = bcc?.parsedAddresses
        
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
    
    var hasSender: Bool {
        return from != nil
    }
    
    var hasRecipient: Bool {
        let noCc = self.cc?.isEmpty ?? true
        let noBcc = self.bcc?.isEmpty ?? true
        let noRecipient = to.isEmpty && noCc && noBcc
        return !noRecipient
    }
}

extension Mail {
    private var headers: [String: String] {
        var fields = [String: String]()
        fields["MESSAGE-ID"] = messageId
        fields["DATE"] = date.smtpFormatted
        fields["FROM"] = from?.mime ?? ""
    
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

/// Name and address used in mail "From", "To", "Cc" and "Bcc" fields.
public struct NameAddressPair {
    
    /// The name of the person. It will be an empty string if no name could be
    /// extracted.
    public let name: String
    
    /// The email address of the person.
    public let address: String
    
    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
    
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
