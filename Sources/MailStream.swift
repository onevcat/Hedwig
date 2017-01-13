//
//  MailStream.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/3.
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
    
    var shouldEncode = false
    
    let mail: Mail
    
    init(mail: Mail, onData: DataHandler?) {
        self.mail = mail
        self.onData = onData
    }
    
    func stream() throws {
        try streamHeader()
        
        if mail.hasAttachment {
            try streamMixed()
        } else {
            try streamText()
        }
    }
    
    func streamHeader() throws {
        let header = mail.headersString + CRLF
        send(header)
    }
    
    func streamText() throws {
        let text = mail.text.embededForText()
        try streamText(text: text)
    }
    
    func streamMixed() throws {
        let boundary = String.createBoundary()
        let mixedHeader = String.mixedHeader(boundary: boundary)
        
        send(mixedHeader)
        
        send(boundary.startLine)
        if mail.alternative != nil {
            try streamAlternative()
        } else {
            try streamText()
        }
        try streamAttachments(mail.attachments, boundary: boundary)
    }
    
    func streamAlternative() throws {
        let boundary = String.createBoundary()
        let alternativeHeader = String.alternativeHeader(boundary: boundary)
        send(alternativeHeader)
        
        send(boundary.startLine)
        try streamText()
        
        let alternative = mail.alternative!
        send(boundary.startLine)
        try streamAttachment(attachment: alternative)
        
        send(boundary.endLine)
    }
    
    func streamAttachment(attachment: Attachment) throws {
        let relatedBoundary: String
        let hasRelated = !attachment.related.isEmpty
        
        if hasRelated {
            relatedBoundary = String.createBoundary()
            let relatedHeader = String.relatedHeader(boundary: relatedBoundary)
            send(relatedHeader)
            send(relatedBoundary.startLine)
        } else {
            relatedBoundary = ""
        }
        
        let attachmentHeader = attachment.headerString  + CRLF + CRLF
        send(attachmentHeader)
        
        switch attachment.type {
        case .file(let file): try streamFile(at: file.path)
        case .html(let html): try streamHTML(text: html.content)
        case .data(let data): try streamData(data: data.data)
        }
        
        send(CRLF)
        
        if hasRelated {
            send("\(CRLF)\(CRLF)")
            try streamAttachments(attachment.related, boundary: relatedBoundary)
        }
    }
    
    func streamAttachments(_ attachments: [Attachment], boundary: String)
        throws
    {
        for attachement in attachments {
            send(boundary.startLine)
            try streamAttachment(attachment: attachement)
        }
        send(boundary.endLine)
    }
    
    func streamFile(at path: String) throws {
        var isDirectory: ObjCBool = false
        let fileExist = FileManager.default
            .fileExists(atPath: path, isDirectory: &isDirectory)
        
        #if os(Linux)
        let directory: Bool = isDirectory
        #else
        let directory: Bool = isDirectory.boolValue
        #endif     
        guard fileExist && !directory else {   
            throw MailStreamError.fileNotExist
        }
        
        shouldEncode = true
        inputStream = InputStream(fileAtPath: path)!
        try loadBytes()
        shouldEncode = false
    }
    
    func streamData(data: Data) throws {
        shouldEncode = true
        inputStream = InputStream(data: data)
        try loadBytes()
        shouldEncode = false
    }
    
    func streamHTML(text: String) throws {
        shouldEncode = true
        try streamText(text: text)
        shouldEncode = false
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
                let toSend = Array(buffer.dropLast(bufferLength - count))
                onData?( shouldEncode ? toSend.base64Data : toSend )
            }
        }
        
        guard stream.streamStatus == .atEnd else {
            throw MailStreamError.streamReadingFailed
        }
    }
}

extension InputStream {
    convenience init(text: String) throws {
        guard let data =
            text.data(using: .utf8, allowLossyConversion: false) else
        {
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
        return "Content-Type: multipart/mixed; boundary=\"\(boundary)\"\(CRLF)\(CRLF)"
    }
    
    static func alternativeHeader(boundary: String) -> String {
        return "Content-Type: multipart/alternative; boundary=\"\(boundary)\"\(CRLF)\(CRLF)"
    }
    
    static func relatedHeader(boundary: String) -> String {
        return "Content-Type: multipart/related; boundary=\"\(boundary)\"\(CRLF)\(CRLF)"
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

