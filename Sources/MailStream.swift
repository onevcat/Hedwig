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
    case streamReadingErrored
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
        
    }
    
    func streamHeader() throws {
        inputStream = InputStream(data: Data())
        try loadBytes()
    }
    
    func streamText(string: String) throws {
        
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
            throw MailStreamError.streamReadingErrored
        }
    }
}
