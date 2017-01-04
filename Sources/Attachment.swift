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
        let mime: String?
        let name: String?
        let inline: Bool
    }
    
    struct HTMLProperty {
        let content: String
        let alternative: Bool
        let inline: Bool
    }
    
    enum AttachmentType {
        case file(FileProperty)
        case html(HTMLProperty)
    }
    
    let type: AttachmentType
    let additionalHeaders: [String: String]?
    
    init(filePath: String, mime: String? = nil, name: String? = nil, inline: Bool = false, additionalHeaders: [String: String]? = nil) {
        
        let mime = mime ?? filePath.guessedMimeType
        let name = name ?? NSString(string: filePath).lastPathComponent
        let fileProperty = FileProperty(path: filePath, mime: mime, name: name, inline: inline)
        self.init(type: .file(fileProperty), additionalHeaders: additionalHeaders)
    }
    
    init(htmlContent: String, alternative: Bool = false, inline: Bool = false, additionalHeaders: [String: String]? = nil) {
        let htmlProperty = HTMLProperty(content: htmlContent, alternative: alternative, inline: inline)
        self.init(type: .html(htmlProperty), additionalHeaders: additionalHeaders)
    }
    
    init(type: AttachmentType, additionalHeaders: [String: String]? = nil) {
        self.type = type
        self.additionalHeaders = additionalHeaders
    }
}

extension Attachment {
    var isAlternative: Bool {
        if case .html(let p) = type, p.alternative {
            return true
        }
        return false
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
