//
//  SMTP.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//

import Foundation
import TLS

struct SMTP {
    
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
    
    func connect() throws {
        let socket = try TLS.Socket(mode: .client, hostname: "smtp.zoho.com", port: 465)
        try socket.connect(servername: "smtp.zoho.com")
        try socket.send("GET / HTTP/1.0\r\n\r\n".toBytes())
        
        let received = try socket.receive(max: 65_536).toString()
        try socket.close()
        
        print(received)
    }
}
