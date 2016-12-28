//
//  SMTPSocket.swift
//  Hedwig
//
//  Created by Wei Wang on 2016/12/27.
//
//

import Foundation
import TLS
import Socks

protocol Sock {
    func send(bytes: [UInt8]) throws
    func receive() throws -> String
    func connect(servername: String) throws
    func close() throws
}

struct SMTPSocket {
    let sock: Sock
    
    func connect(servername: String) throws -> SMTPResponse {
        try sock.connect(servername: servername)
        return try SMTPResponse(string: try sock.receive())
    }
    
    func send(_ string: String) throws -> SMTPResponse {
        try sock.send(bytes: string.toBytes())
        
        var parsed: SMTPResponse? = nil
        var multiple = false
        
        var result = ""
        
        while parsed == nil {
            let s = try sock.receive()
            result.append(s)
            do {
                let r = try SMTPResponse(string: s)
                parsed = r
            } catch {
                multiple = true
            }
        }
        
        if multiple {
            return SMTPResponse(code: parsed!.code, data: result)
        } else {
            return parsed!
        }
    }
    
    func close() throws {
        try sock.close()
    }
}

extension TLS.Socket: Sock {
    func send(bytes: [UInt8]) throws {
        try send(bytes)
    }
    func receive() throws -> String {
        return try receive(max: 65_535).toString()
    }
}

extension TCPClient: Sock {
    func receive() throws -> String {
        let bytes: [UInt8] = try receive(maxBytes: 65_535)
        return try bytes.toString()
    }
    
    func connect(servername: String) throws {
        
    }
}
