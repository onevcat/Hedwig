//
//  Attachment.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/4.
//
//

import Foundation
import MimeType

struct Attachment {
    
    struct FileProperty {
        let path: String
        let mime: String
        let name: String
        let inline: Bool
    }
    
    struct HTMLProperty {
        let content: String
        let characterSet: String
        let alternative: Bool
    }
    
    struct DataProperty {
        let data: Data
        let mime: String
        let name: String
        let inline: Bool
    }
    
    enum AttachmentType {
        case file(FileProperty)
        case html(HTMLProperty)
        case data(DataProperty)
    }
    
    let type: AttachmentType
    let additionalHeaders: [String: String]
    let related: [Attachment]
    
    init(filePath: String, mime: String? = nil, name: String? = nil, inline: Bool = false, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        
        let mime = mime ??  MimeType(path: filePath).value
        let name = name ?? NSString(string: filePath).lastPathComponent
        let fileProperty = FileProperty(path: filePath, mime: mime, name: name, inline: inline)
        self.init(type: .file(fileProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    init(data: Data, mime: String, name: String, inline: Bool = false, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        let dataProperty = DataProperty(data: data, mime: mime, name: name, inline: inline)
        self.init(type: .data(dataProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    init(htmlContent: String, characterSet: String = "utf-8", alternative: Bool = true, inline: Bool = true, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        let htmlProperty = HTMLProperty(content: htmlContent, characterSet: characterSet, alternative: alternative)
        self.init(type: .html(htmlProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    init(type: AttachmentType, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        self.type = type
        self.additionalHeaders = additionalHeaders
        self.related = related
    }
}

extension Attachment.FileProperty: Equatable {
    static func ==(lhs: Attachment.FileProperty, rhs: Attachment.FileProperty) -> Bool {
        return lhs.path == rhs.path &&
            lhs.mime == rhs.mime &&
            lhs.name == rhs.name &&
            lhs.inline == rhs.inline
    }
}

extension Attachment.DataProperty: Equatable {
    static func ==(lhs: Attachment.DataProperty, rhs: Attachment.DataProperty) -> Bool {
        return lhs.data == rhs.data &&
            lhs.mime == rhs.mime &&
            lhs.name == rhs.name &&
            lhs.inline == rhs.inline
    }
}

extension Attachment.HTMLProperty: Equatable {
    static func ==(lhs: Attachment.HTMLProperty, rhs: Attachment.HTMLProperty) -> Bool {
        return lhs.content == rhs.content &&
            lhs.characterSet == rhs.characterSet &&
            lhs.alternative == rhs.alternative
    }
}


extension Attachment: Equatable {
    static func ==(lhs: Attachment, rhs: Attachment) -> Bool {
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
    var isAlternative: Bool {
        if case .html(let p) = type, p.alternative {
            return true
        }
        return false
    }
    
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
