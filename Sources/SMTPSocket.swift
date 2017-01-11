//
//  SMTPSocket.swift
//  Hedwig
//
//  Created by Wei Wang on 2016/12/27.
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
import TLS
import Socks
import SocksCore
import CLibreSSL

protocol Sock {
    func send(bytes: [UInt8]) throws
    func receive() throws -> [String]
    func connect(servername: String) throws
    func close() throws
    var internalSocket: TCPInternetSocket { get }
}

struct SMTPSocket {
    let sock: Sock
    
    func connect(servername: String) throws -> SMTPResponse {
        try sock.connect(servername: servername)
        let result = try sock.receive()
        
        guard result.count == 1 else {
            throw SMTP.SMTPError.badResponse
        }
        
    
        return try SMTPResponse(string: result[0])
    }
    
    func send(_ string: String) throws -> SMTPResponse {
        logInTest("C: \(string)")
        try sock.send(bytes: (string + CRLF).toBytes())
        
        var parsed: SMTPResponse? = nil
        var response = try sock.receive()
        var multiple = false
        var result = [String]()
        
        // Workaround for different socket buffer implementation.
        // Some server prefer to buffer one line a time, while some 
        // other buffer all lines.
        if response.count == 1 {
            // One line case. Keep getting until can be parsed correctly.
            repeat {
                result.append(response[0])
                do {
                    parsed = try SMTPResponse(string: response[0])
                } catch {
                    multiple = true
                    response = try sock.receive()
                }
            } while parsed == nil
        } else {
            // Multiple lines. Try parse until get a correct line.
            multiple = true
            for res in response {
                result.append(res)
                if parsed == nil {
                    parsed = try? SMTPResponse(string: res)
                }
            } 
        }
        
        guard let parsedRes = parsed else {
            throw SMTP.SMTPError.badResponse
        }

        let r: SMTPResponse
        
        if multiple {
            r = SMTPResponse(code: parsedRes.code,
                             data: result.joined(separator: "\n"))
        } else {
            r = parsedRes
        }
        
        logInTest("S: \(r.data)")
        return r
    }
    
    func close() throws {
        try sock.close()
    }
}

extension TLS.Socket: Sock {
    func send(bytes: [UInt8]) throws {
        try send(bytes)
    }
    
    func receive() throws -> [String] {
        let text = try receive(max: 65_535).toString()
        return text.seperated
    }
    
    var internalSocket: TCPInternetSocket {
        return socket
    }
}

extension TLS.Socket {
    /// Convert an existing TCP socket to a TLS socket.
    convenience init(existing socket: TCPInternetSocket,
                     certificates: Certificates,
                     cipher: Config.Cipher,
                     proto: [Config.TLSProtocol],
                     hostName: String) throws
    {
        let context = try Context(mode: .client)
        let config = try Config(context: context,
                                certificates: certificates,
                                cipher: cipher,
                                proto: proto)

        try self.init(config: config, socket: socket)
        tls_connect_socket(config.context.cContext, socket.descriptor, hostName)
        
        currSocket = socket
        currContext = config.context.cContext
    }
}

extension TCPClient: Sock {
    
    convenience init(hostName: String, port: Port) throws {
        let address = InternetAddress(hostname: hostName, port: port)
        let socket = try TCPInternetSocket(address: address)
        try self.init(alreadyConnectedSocket: socket)
    }
    
    func receive() throws -> [String] {
        let text = try receive(maxBytes: 65_535).toString()
        return text.seperated
    }
    
    func connect(servername: String) throws {
        try socket.connect()
    }
    
    var internalSocket: TCPInternetSocket {
        return socket
    }
}

extension String {
    var seperated: [String] {
        return components(separatedBy: CRLF).filter { $0 != "" }
    }
}
