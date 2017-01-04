//
//  MailStream.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/3.
//
//

import Foundation

typealias DataHandler = ([UInt8]) -> Void

let bufferLength = 76 * 24 * 7

enum MailStreamError: Error {
    case streamNotExist
    case streamReadingFailed
    case encoding
    case fileNotExist
}

class MailStream: NSObject {
    
    var onData: DataHandler? = nil
    
    var inputStream: InputStream?
    var buffer = Array<UInt8>(repeating: 0, count: bufferLength)
    
    let mail: Mail
    
    init(mail: Mail, onData: DataHandler?) {
        self.mail = mail
        self.onData = onData
    }
    
    func stream() throws {
        try streamHeader()
        
        if let attachments = mail.attachments, !attachments.isEmpty {
            
            let containsAlternative = attachments.contains { $0.isAlternative }
            try streamMixed(alternative: containsAlternative)
        } else {
            try streamText()
        }
    }
    
    func streamHeader() throws {
        let header = mail.headersString + CRLF
        inputStream = try InputStream(text: header)
        try loadBytes()
    }
    
    func streamText() throws {
        let text = mail.text.embededForText()
        try streamText(text: text)
    }
    
    func streamMixed(alternative: Bool) throws {
        let boundary = String.createBoundary()
        let mixHeader = String.mixedHeader(boundary: boundary)
        inputStream = try InputStream(text: mixHeader)
        try loadBytes()

        if alternative {
            try streamAlternative()
        } else {
            try streamText()
        }
        try streamAttachments(boundary: boundary)
    }
    
    func streamAlternative() throws {
        let boundary = String.createBoundary()
        let alternativeHeader = String.alternativeHeader(boundary: boundary)
        inputStream = try InputStream(text: alternativeHeader)
        try loadBytes()
        
        try streamText()
        
        send(boundary.startLine)
        
        let alternativeTarget = (mail.attachments?.last { $0.isAlternative })!
        try streamAttachment(attachment: alternativeTarget)
        
        send(boundary.endLine)
    }
    
    func streamAttachment(attachment: Attachment) throws {
        switch attachment.type {
        case .file(let file): try streamFileContent(at: file.path)
        case .html(let html): try streamText(text: html.content.base64EncodedString)
        }
    }
    
    func streamAttachments(boundary: String) throws {
        for attachement in mail.attachments! {
            send(boundary.startLine)
            try streamAttachment(attachment: attachement)
        }
        send(boundary.endLine)
    }
    
    func streamFileContent(at path: String) throws {
        var isDirectory: ObjCBool = false
        let fileExist = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        
        guard fileExist && !isDirectory.boolValue else {
            throw MailStreamError.fileNotExist
        }
        
        inputStream = InputStream(fileAtPath: path)!
        try loadBytes()
    }
    
    func streamText(text: String) throws {
        inputStream = try InputStream(text: text)
        try loadBytes()
    }
    
    func send(_ text: String) {
        onData?(Array(text.utf8))
    }
    
    private func loadBytes() throws {
        guard let stream = inputStream else {
            throw MailStreamError.streamNotExist
        }
        
        stream.open()
        defer { stream.close() }
        
        while stream.streamStatus != .atEnd && stream.streamStatus != .error {
            let count = stream.read(&buffer, maxLength: bufferLength)
            if count != 0 {
                onData?(Array(buffer.dropLast(bufferLength - count)))
            }
        }
        
        guard stream.streamStatus == .atEnd else {
            throw MailStreamError.streamReadingFailed
        }
    }
}

extension InputStream {
    convenience init(text: String) throws {
        guard let data =  text.data(using: .utf8, allowLossyConversion: false) else {
            throw MailStreamError.encoding
        }
        self.init(data: data)
    }
}

extension String {
    
    static func createBoundary() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    static let plainTextHeader = "Content-Type: text/plain; charset=utf-8\(CRLF)Content-Transfer-Encoding: 7bit\(CRLF)Content-Disposition: inline\(CRLF)\(CRLF)"
    
    static func mixedHeader(boundary: String) -> String {
        return "Content-Type: multipart/mixed; boundary=\"\(boundary)\"\(CRLF)\(CRLF)--\(boundary)\(CRLF)"
    }
    
    static func alternativeHeader(boundary: String) -> String {
        return "Content-Type: multipart/alternative; boundary=\"\(boundary)\"\(CRLF)\(CRLF)--\(boundary)\(CRLF)"
    }
    
    func embededForText() -> String {
        return "\(String.plainTextHeader)\(self)\(CRLF)\(CRLF)"
    }
}

extension String {
    var startLine: String {
        return "--\(self)\(CRLF)"
    }
    
    var endLine: String {
        return "\(CRLF)--\(self)--\(CRLF)\(CRLF)"
    }
}

extension Array {
    func last(where condition: (Element) -> Bool) -> Element? {
        return reversed().first(where: condition)
    }
}
