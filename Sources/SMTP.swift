//
//  SMTP.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//

import Foundation
import TLS
import Socks

protocol SMTPSocket {
    func send(data: Data) throws
    func receive(maxBytes: Int) throws -> Data
    func connect(servername: String) throws
    func close() throws
}

extension TLS.Socket: SMTPSocket {
    func send(data: Data) throws {
        try send(data.array)
    }
    
    func receive(maxBytes: Int) throws -> Data {
        return try Data(bytes: receive(max: maxBytes))
    }
}

extension TCPClient: SMTPSocket {
    func send(data: Data) throws {
        try send(bytes: data.array)
    }
    
    func receive(maxBytes: Int) throws -> Data {
        let bytes: [UInt8] = try receive(maxBytes: maxBytes)
        return Data(bytes: bytes)
    }
    
    func connect(servername: String) throws {
        fatalError("This should not be called. TCP clinet will connect as soon as created.")
    }
}

struct SMTP {
    
    let hostName: String
    let port: Port
    let user: String?
    let password: String?
    
    private(set) var socket: SMTPSocket
    
    private var state: State
    private var loggedIn: Bool
    
    enum SMTPError: Error {
        case couldNotConnect
        case timeOut
        case badResponse
        case nonConnection
        case authFailed
        case authNotSupported
        case connectionClosed
        case connectionEnded
        case connectionAuth
        case unknown
    }
    
    enum State {
        case notConnected
        case connecting
        case connected
    }
    
    enum AuthMethod: String {
        case plain = "PLAIN"
        case cramMD5 = "CRAM-MD5"
        case login = "LOGIN"
        case xOauth2 = "XOAUTH2"
    }
    
    init(hostName: String, user: String?, password: String?,
         port: Port? = nil, ssl: Bool = true, tls: Bool = true) throws
    {
        self.hostName = hostName
        self.user = user
        self.password = password
        
        self.port = {
            if let port = port {
                return port
            } else {
                switch (ssl, tls) {
                case (true, _):      return .ssl
                case (false, true):  return .tls
                case (false, false): return .regular
                }
            }
        }()
        
        self.loggedIn = (user != nil && password != nil) ? false : true
        self.state = .notConnected
        
        if ssl {
            // TLS.Socket will never throw.
            self.socket = try TLS.Socket(mode: .client, hostname: hostName, port: self.port)
        } else {
            let address = InternetAddress(hostname: hostName, port: self.port)
            self.socket = try TCPClient(address: address)
        }
    }
    
    func connect() throws {
        try socket.connect(servername: hostName)
    }
    
    func send(data: Data) throws {
        try socket.send(data: data)
    }
    
    mutating func close() throws {
        try socket.close()
        state = .notConnected
        loggedIn = (user != nil && password != nil) ? false : true
        
    }
}
