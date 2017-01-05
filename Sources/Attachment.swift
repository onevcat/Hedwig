//
//  Attachment.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/4.
//
//

import Foundation

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
    
    enum AttachmentType {
        case file(FileProperty)
        case html(HTMLProperty)
    }
    
    let type: AttachmentType
    let additionalHeaders: [String: String]
    let related: [Attachment]
    
    init(filePath: String, mime: String? = nil, name: String? = nil, inline: Bool = false, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        
        let mime = mime ?? filePath.guessedMimeType
        let name = name ?? NSString(string: filePath).lastPathComponent
        let fileProperty = FileProperty(path: filePath, mime: mime, name: name, inline: inline)
        self.init(type: .file(fileProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    init(htmlContent: String, characterSet: String = "utf-8", alternative: Bool = false, inline: Bool = false, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
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
            result["CONTENT-DISPOSITION"] = fileProperty.inline ? "inline" : "attachment; filename=\"\(fileProperty.name.mimeEncoded ?? "attachment")\""
        case .html(let htmlProperty):
            result["CONTENT-TYPE"] = "text/html; charset=\(htmlProperty.characterSet)"
            result["CONTENT-DISPOSITION"] = "inline"
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

extension String {
    var guessedMimeType: String {
        guard let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, NSString(string: self).pathExtension as CFString, nil) else {
            return "application/octet-stream"
        }
        
        guard let mimeType = UTTypeCopyPreferredTagWithClass (UTI.takeUnretainedValue(), kUTTagClassMIMEType) else {
            return "application/octet-stream"
        }
        return mimeType.takeUnretainedValue() as String
    }
}
