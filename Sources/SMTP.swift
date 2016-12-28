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

private func logError(error: SMTP.SMTPError, message: String? = nil) {
    print("[Hedwig] SMTP Error: \(error). \(message)")
}

typealias Validation = (enabled: Bool, certificate: Certificates, cipher: Config.Cipher, protocols: [Config.TLSProtocol])
let defaultValidation: Validation = (enabled: false, certificate: .defaults, cipher: .compat, protocols: [.all])


class SMTP {
    
    private let hostName: String
    private let port: Port
    private let user: String?
    private let password: String?
    
    private let ssl: Validation
    private let tls: Validation
    
    private var socket: SMTPSocket
    
    private var state: State
    private var loggedIn: Bool
    
    private var secure: Bool = false
    
    private var features: [String: Any] = [:]
    
    enum SMTPError: Error, CustomStringConvertible {
        case couldNotConnect
        case timeOut
        case badResponse
        case noConnection
        case authFailed
        case authNotSupported
        case connectionClosed
        case connectionEnded
        case connectionAuth
        case unknown
        
        var description: String {
            let message: String
            switch self {
            case .couldNotConnect: message = ""
            case .timeOut: message = ""
            case .badResponse: message = "bad response"
            case .noConnection: message = "no connection has been established"
            case .authFailed: message = ""
            case .authNotSupported: message = ""
            case .connectionClosed: message = ""
            case .connectionEnded: message = ""
            case .connectionAuth: message = ""
            case .unknown: message = ""
            }
            return message
        }
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
         port: Port? = nil, ssl: Validation = defaultValidation, tls: Validation = defaultValidation) throws
    {
        self.hostName = hostName
        self.user = user
        self.password = password
        
        self.port = {
            if let port = port {
                return port
            } else {
                switch (ssl.enabled, tls.enabled) {
                case (true, _):      return .ssl
                case (false, true):  return .tls
                case (false, false): return .regular
                }
            }
        }()
        
        self.ssl = ssl
        self.tls = tls
        
        self.loggedIn = (user != nil && password != nil) ? false : true
        self.state = .notConnected
        
        if ssl.enabled {
            let sock = try TLS.Socket(mode: .client,
                                      hostname: hostName,
                                      port: self.port,
                                      certificates: ssl.certificate,
                                      cipher: ssl.cipher,
                                      proto: ssl.protocols)
            self.socket = SMTPSocket(sock: sock)
        } else {
            let address = InternetAddress(hostname: hostName, port: self.port)
            let sock = try TCPClient(address: address)
            self.socket = SMTPSocket(sock: sock)
        }
    }
    
    func connect() throws -> SMTPResponse {
        self.state = .connecting
        
        let response = try socket.connect(servername: hostName)
        guard response.code == 220 else {
            let error = SMTPError.badResponse
            logError(error: error, message: "\(error.description) on connecting: \(response.message)")
            throw error
        }

        self.state = .connected
        if ssl.enabled && !tls.enabled {
            secure = true
        }
        
        return response
    }
    
    func send(_ string: String) throws -> SMTPResponse {
        guard state == .connected else {
            try close()
            let error = SMTPError.noConnection
            logError(error: error, message: "no connection has been established")
            throw error
        }
        
        return try socket.send(string)
    }
    
    func send(_ command: SMTPCommand) throws -> SMTPResponse {
        let response = try send(command.text + CRLF)
        
        guard command.expectedCodes.contains(response.code) else {
            let error = SMTPError.badResponse
            logError(error: error, message: "\(error.description) on command: \(command), response: \(response.message)")
            throw error
        }
        
        return response
    }
    
    func helo(domain: String) throws -> SMTPResponse {
        let response = try send(.helo(domain))
        updateFeatures(response.data)
        return response
    }
    
    func ehlo(domain: String) throws -> SMTPResponse {
        let response = try send(.ehlo(domain))
        updateFeatures(response.data)
        if tls.enabled && !secure {
            try starttls()
            return try ehlo(domain: domain)
        }
        
        return response
    }
    
    func starttls() throws {
        _ = try send(.starttls)
        let sock = try TLS.Socket(mode: .client,
                                  hostname: hostName,
                                  port: self.port,
                                  certificates: tls.certificate,
                                  cipher: tls.cipher,
                                  proto: tls.protocols)
        socket = SMTPSocket(sock: sock)
        _ = try connect()
        secure = true
    }
    
    func close() throws {
        try socket.close()
        state = .notConnected
        loggedIn = (user != nil && password != nil) ? false : true
        secure = false
    }
    
    func updateFeatures(_ s: String) {
        features = s.featureDictionary()
    }
}

extension String {
    static let featureMather = try! NSRegularExpression(pattern: "^(?:\\d+[\\-=]?)\\s*?([^\\s]+)(?:\\s+(.*)\\s*?)?$", options: [])
    
    func featureDictionary() -> [String: Any] {
        
        var feature = [String: Any]()
        
        let entries = replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n")
        entries.forEach {entry in
            let match = String.featureMather.groups(in: entry)
            if match.count == 2 {
                feature[match[0]] = match[1]
            } else if match.count == 1 {
                feature[match[0]] = true
            }
        }
        return feature
    }
}
