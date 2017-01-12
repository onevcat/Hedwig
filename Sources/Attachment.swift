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

public struct Attachment {
    
    public struct FileProperty {
        public let path: String
        public let mime: String
        public let name: String
        public let inline: Bool
        
        public init(path: String, mime: String, name: String, inline: Bool) {
            self.path = path
            self.mime = mime
            self.name = name
            self.inline = inline
        }
    }
    
    public struct HTMLProperty {
        public let content: String
        public let characterSet: String
        public let alternative: Bool
        
        public init(content: String, characterSet: String, alternative: Bool) {
            self.content = content
            self.characterSet = characterSet
            self.alternative = alternative
        }
    }
    
    public struct DataProperty {
        public let data: Data
        public let mime: String
        public let name: String
        public let inline: Bool
        
        public init(data: Data, mime: String, name: String, inline: Bool) {
            self.data = data
            self.mime = mime
            self.name = name
            self.inline = inline
        }
    }
    
    public enum AttachmentType {
        case file(FileProperty)
        case html(HTMLProperty)
        case data(DataProperty)
    }
    
    public let type: AttachmentType
    public let additionalHeaders: [String: String]
    public let related: [Attachment]
    
    public var isAlternative: Bool {
        if case .html(let p) = type, p.alternative {
            return true
        }
        return false
    }
    
    public init(filePath: String, mime: String? = nil, name: String? = nil, inline: Bool = false, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        
        let mime = mime ??  MimeType(path: filePath).value
        let name = name ?? NSString(string: filePath).lastPathComponent
        let fileProperty = FileProperty(path: filePath, mime: mime, name: name, inline: inline)
        self.init(type: .file(fileProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    public init(data: Data, mime: String, name: String, inline: Bool = false, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        let dataProperty = DataProperty(data: data, mime: mime, name: name, inline: inline)
        self.init(type: .data(dataProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    public init(htmlContent: String, characterSet: String = "utf-8", alternative: Bool = true, inline: Bool = true, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        let htmlProperty = HTMLProperty(content: htmlContent, characterSet: characterSet, alternative: alternative)
        self.init(type: .html(htmlProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    public init(type: AttachmentType, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        self.type = type
        self.additionalHeaders = additionalHeaders
        self.related = related
    }
}

extension Attachment.FileProperty: Equatable {
    public static func ==(lhs: Attachment.FileProperty, rhs: Attachment.FileProperty) -> Bool {
        return lhs.path == rhs.path &&
            lhs.mime == rhs.mime &&
            lhs.name == rhs.name &&
            lhs.inline == rhs.inline
    }
}

extension Attachment.DataProperty: Equatable {
    public static func ==(lhs: Attachment.DataProperty, rhs: Attachment.DataProperty) -> Bool {
        return lhs.data == rhs.data &&
            lhs.mime == rhs.mime &&
            lhs.name == rhs.name &&
            lhs.inline == rhs.inline
    }
}

extension Attachment.HTMLProperty: Equatable {
    public static func ==(lhs: Attachment.HTMLProperty, rhs: Attachment.HTMLProperty) -> Bool {
        return lhs.content == rhs.content &&
            lhs.characterSet == rhs.characterSet &&
            lhs.alternative == rhs.alternative
    }
}


extension Attachment: Equatable {
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
            var attachmentDisposition = fileProperty.inline ? "inline" : "attachment"
            if let mime = fileProperty.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            result["CONTENT-DISPOSITION"] = attachmentDisposition
        case .html(let htmlProperty):
            result["CONTENT-TYPE"] = "text/html; charset=\(htmlProperty.characterSet)"
            result["CONTENT-DISPOSITION"] = "inline"
        case .data(let dataProperty):
            result["CONTENT-TYPE"] = dataProperty.mime
            var attachmentDisposition = dataProperty.inline ? "inline" : "attachment"
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
