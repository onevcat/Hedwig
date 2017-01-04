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
            
        } else {
            try streamText()
        }
    }
    
    func streamHeader() throws {
        let header = mail.headersString + CRLF
        guard let data =  header.data(using: .utf8, allowLossyConversion: false) else {
            throw MailStreamError.encoding
        }
        
        inputStream = InputStream(data: data)
        try loadBytes()
    }
    
    func streamText() throws {
        let text = mail.text.embededForText()
        guard let data =  text.data(using: .utf8, allowLossyConversion: false) else {
            throw MailStreamError.encoding
        }
        
        inputStream = InputStream(data: data)
        try loadBytes()
    }
    
    func streamMixed() throws {
        let mixHeader = ""
    }
    
    func streamFile(path: String) throws {
        
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

extension String {
    
    static let plainTextHeader = ""
    
    func embededForText() -> String {
        return "Content-Type: text/plain; charset=utf-8\(CRLF)Content-Transfer-Encoding: 7bit\(CRLF)Content-Disposition: inline\(CRLF)\(CRLF)\(self)\(CRLF)\(CRLF)"
    }
}
