//
//  Attachment.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/4.
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
import MimeType

/// Presentation an attachement contained in a `Mail`.
public struct Attachment {
    
    /// Properties when the attachment is a file.
    public struct FileProperty {
        
        /// Path in the local disk of the file.
        public let path: String
        
        /// MIME type of the file.
        public let mime: String
        
        /// File name which will be presented in the mail.
        public let name: String
        
        /// Whether the file could be inline or not. When set to `true`, the
        /// attachment “Content-Disposition” header will be `inline`, otherwise
        /// it will be `attachment`.
        public let inline: Bool
        
        /// Initilize a file property.
        ///
        /// - Parameters:
        ///   - path: File path.
        ///   - mime: MIME type of the file.
        ///   - name: File name which will be presented in the mail.
        ///   - inline: Whether the file could be inline or not. When set to 
        ///             `true`, the attachment “Content-Disposition” header 
        ///             will be `inline`, otherwise it will be `attachment`.
        public init(path: String, mime: String, name: String, inline: Bool) {
            self.path = path
            self.mime = mime
            self.name = name
            self.inline = inline
        }
    }
    
    /// Properties when the attachment is an HTML string.
    public struct HTMLProperty {
        
        /// Content of the HTML string.
        public let content: String
        
        /// Charater encoding set should be used.
        public let characterSet: String
        
        /// Whether this HTML could be alternative for plain text.
        public let alternative: Bool
        
        /// Initilize an HTML property.
        ///
        /// - Parameters:
        ///   - content: Content of the HTML string.
        ///   - characterSet: Charater encoding set should be used.
        ///   - alternative: Whether this HTML could be alternative for plain 
        ///     text.
        public init(content: String, characterSet: String, alternative: Bool) {
            self.content = content
            self.characterSet = characterSet
            self.alternative = alternative
        }
    }
    
    /// Properties when the attachment is some raw data.
    public struct DataProperty {
        
        /// Data content.
        public let data: Data
        
        /// MIME type of the data.
        public let mime: String
        
        /// File name which will be presented in the mail.
        public let name: String
        
        /// Whether the data could be inline or not. When set to `true`, the
        /// attachment “Content-Disposition” header will be `inline`, otherwise
        /// it will be `attachment`.
        public let inline: Bool
        
        /// Initilize a file property.
        ///
        /// - Parameters:
        ///   - data: Data content.
        ///   - mime: MIME type of the file.
        ///   - name: File name which will be presented in the mail.
        ///   - inline: Whether the file could be inline or not. When set to
        ///             `true`, the attachment “Content-Disposition” header
        ///             will be `inline`, otherwise it will be `attachment`.
        public init(data: Data, mime: String, name: String, inline: Bool) {
            self.data = data
            self.mime = mime
            self.name = name
            self.inline = inline
        }
    }
    
    /// Attachment type.
    ///
    /// - file: The attachment is a file in local disk.
    /// - html: The attachment is an HTML string.
    /// - data: The attachment is some raw data.
    public enum AttachmentType {
        /// The attachment is a file in local disk.
        case file(FileProperty)
        /// The attachment is an HTML string.
        case html(HTMLProperty)
        /// The attachment is some raw data.
        case data(DataProperty)
    }
    
    /// The type of current attachment.
    public let type: AttachmentType

    /// Additional headers when sending current attachment with a `Mail`.
    public let additionalHeaders: [String: String]
    
    /// Related attachments of current attachment. The `related` ones will be 
    /// contained in a "related" boundary in the mail body.
    public let related: [Attachment]
    
    /// Whether this attachment is an alternative one.
    public var isAlternative: Bool {
        if case .html(let p) = type, p.alternative {
            return true
        }
        return false
    }
    
    /// Initilize a file attachment.
    ///
    /// - Parameters:
    ///   - filePath: Path in the local disk of the file.
    ///   - mime: MIME type of the file. Default is `nil`, which means leave
    ///           to Hedwig to guess the type from file extension. If Hedwig can
    ///           not determine the MIME type, a general binary type 
    ///           "application/octet-stream" will be used.
    ///   - name: File name which will be presented in the mail. Default is the 
    ///           file name from `filePath`.
    ///   - inline: Whether the file could be inline or not. When set to `true`,
    ///             the attachment “Content-Disposition” header will be `inline`, 
    ///             otherwise it will be `attachment`. If you want to embed the 
    ///             file in mail content, set it to `true`. Otherwise if you
    ///             need it to be a standalone attachment, `false`.
    ///   - additionalHeaders: Additional headers when sending current
    ///                        attachment with a `Mail`.
    ///   - related: Related attachments of current attachment. The `related`
    ///              ones will be contained in a "related" boundary in the mail
    ///              body.
    public init(filePath: String,
                mime: String? = nil,
                name: String? = nil,
                inline: Bool = false,
                additionalHeaders: [String: String] = [:],
                related: [Attachment] = [])
    {
        let mime = mime ??  MimeType(path: filePath).value
        let name = name ?? NSString(string: filePath).lastPathComponent
        let fileProperty = FileProperty(path: filePath, mime: mime, name: name,
                                        inline: inline)
        self.init(type: .file(fileProperty),
                  additionalHeaders: additionalHeaders, related: related)
    }
    
    /// Initilize a data attachment.
    ///
    /// - Parameters:
    ///   - data: Raw data will be sent as attachment.
    ///   - mime: MIME type of the data.
    ///   - name: File name which will be presented in the mail.
    ///   - inline: Whether the file could be inline or not. When set to `true`,
    ///             the attachment “Content-Disposition” header will be `inline`,
    ///             otherwise it will be `attachment`. If you want to embed the
    ///             file in mail content, set it to `true`. Otherwise if you
    ///             need it to be a standalone attachment, `false`.
    ///   - additionalHeaders: Additional headers when sending current
    ///                        attachment with a `Mail`.
    ///   - related: Related attachments of current attachment. The `related`
    ///              ones will be contained in a "related" boundary in the mail
    ///              body.
    public init(data: Data,
                mime: String,
                name: String,
                inline: Bool = false,
                additionalHeaders: [String: String] = [:],
                related: [Attachment] = [])
    {
        let dataProperty = DataProperty(data: data, mime: mime,
                                        name: name, inline: inline)
        self.init(type: .data(dataProperty),
                  additionalHeaders: additionalHeaders, related: related)
    }
    
    
    /// Initilize an HTML attachment.
    ///
    /// - Parameters:
    ///   - htmlContent: Content string of HTML.
    ///   - characterSet: Charater encoding set of `htmlContent`. Default is 
    ///                   "utf-8".
    ///   - alternative: Whether this HTML could be alternative for plain text.
    ///                  Default is `true`, means the HTML content could be
    ///                  alternative for plain text.
    ///   - inline: Whether the HTML could be inline or not. Default is `true`.
    ///   - additionalHeaders: Additional headers when sending current
    ///                        attachment with a `Mail`.
    ///   - related: Related attachments of current attachment. The `related`
    ///              ones will be contained in a "related" boundary in the mail
    ///              body.
    public init(htmlContent: String,
                characterSet: String = "utf-8",
                alternative: Bool = true,
                inline: Bool = true,
                additionalHeaders: [String: String] = [:],
                related: [Attachment] = [])
    {
        let htmlProperty = HTMLProperty(content: htmlContent,
                                        characterSet: characterSet,
                                        alternative: alternative)
        self.init(type: .html(htmlProperty),
                  additionalHeaders: additionalHeaders, related: related)
    }
    
    /// Initilize an attachment with an `AttachmentType`.
    ///
    /// - Parameters:
    ///   - type: The type of attachement.
    ///   - additionalHeaders: Additional headers when sending current
    ///                        attachment with a `Mail`.
    ///   - related: Related attachments of current attachment. The `related`
    ///              ones will be contained in a "related" boundary in the mail
    ///              body.
    public init(type: AttachmentType,
                additionalHeaders: [String: String] = [:],
                related: [Attachment] = [])
    {
        self.type = type
        self.additionalHeaders = additionalHeaders
        self.related = related
    }
}

extension Attachment.FileProperty: Equatable {
    
    /// Whether two `Attachment.FileProperty` should equal.
    /// Two `Attachment.FileProperty` will equal to each other when all 
    /// members equal.
    ///
    /// - Parameters:
    ///   - lhs: Left hand `FileProperty`.
    ///   - rhs: Right hand `FileProperty`
    /// - Returns: `true` if two file properties equal. Otherwise, `false`.
    public static func ==(lhs: Attachment.FileProperty,
                          rhs: Attachment.FileProperty) -> Bool {
        return lhs.path == rhs.path &&
            lhs.mime == rhs.mime &&
            lhs.name == rhs.name &&
            lhs.inline == rhs.inline
    }
}

extension Attachment.DataProperty: Equatable {
    /// Whether two `Attachment.DataProperty` should equal.
    /// Two `Attachment.DataProperty` will equal to each other when all
    /// members equal.
    ///
    /// - Parameters:
    ///   - lhs: Left hand `DataProperty`.
    ///   - rhs: Right hand `DataProperty`
    /// - Returns: `true` if two data properties equal. Otherwise, `false`.
    public static func ==(lhs: Attachment.DataProperty,
                          rhs: Attachment.DataProperty) -> Bool {
        return lhs.data == rhs.data &&
            lhs.mime == rhs.mime &&
            lhs.name == rhs.name &&
            lhs.inline == rhs.inline
    }
}

extension Attachment.HTMLProperty: Equatable {
    /// Whether two `Attachment.HTMLProperty` should equal.
    /// Two `Attachment.HTMLProperty` will equal to each other when all
    /// members equal.
    ///
    /// - Parameters:
    ///   - lhs: Left hand `HTMLProperty`.
    ///   - rhs: Right hand `HTMLProperty`
    /// - Returns: `true` if two HTML properties equal. Otherwise, `false`.
    public static func ==(lhs: Attachment.HTMLProperty,
                          rhs: Attachment.HTMLProperty) -> Bool {
        return lhs.content == rhs.content &&
            lhs.characterSet == rhs.characterSet &&
            lhs.alternative == rhs.alternative
    }
}


extension Attachment: Equatable {
    /// Whether two `Attachment` should equal.
    /// Two `Attachment` will equal to each other when all
    /// members equal.
    ///
    /// - Parameters:
    ///   - lhs: Left hand `Attachment`.
    ///   - rhs: Right hand `Attachment`
    /// - Returns: `true` if two attachments equal. Otherwise, `false`.
    public static func ==(lhs: Attachment, rhs: Attachment) -> Bool {
        switch (lhs.type, rhs.type) {
        case (.file(let p1), .file(let p2)):
            return p1 == p2 && lhs.additionalHeaders == rhs.additionalHeaders
        case (.html(let p1), .html(let p2)):
            return p1 == p2 && lhs.additionalHeaders == rhs.additionalHeaders
        case (.data(let p1), .data(let p2)):
            return p1 == p2 && lhs.additionalHeaders == rhs.additionalHeaders
        default:
            return false
        }
    }
}

extension Attachment {
    private var headers: [String: String] {
        var result = [String: String]()
        switch type {
        case .file(let fileProperty):
            result["CONTENT-TYPE"] = fileProperty.mime
            var attachmentDisposition =
                fileProperty.inline ? "inline" : "attachment"
            if let mime = fileProperty.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            result["CONTENT-DISPOSITION"] = attachmentDisposition
            
            
        case .html(let htmlProperty):
            result["CONTENT-TYPE"] =
                "text/html; charset=\(htmlProperty.characterSet)"
            result["CONTENT-DISPOSITION"] = "inline"
            
            
        case .data(let dataProperty):
            result["CONTENT-TYPE"] = dataProperty.mime
            var attachmentDisposition =
                dataProperty.inline ? "inline" : "attachment"
            
            if let mime = dataProperty.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            result["CONTENT-DISPOSITION"] = attachmentDisposition
            
        }
        
        result["CONTENT-TRANSFER-ENCODING"] = "BASE64"
        for (key, value) in additionalHeaders {
            result[key.uppercased()] = value
        }
        
        return result
    }

    var headerString: String {
        return headers.map { (key, value) in
            return "\(key): \(value)"
            }.joined(separator: CRLF)
    }
}
