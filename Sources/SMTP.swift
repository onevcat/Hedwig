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
    
    fileprivate let hostName: String
    fileprivate let port: Port
    fileprivate let user: String?
    fileprivate let password: String?
    fileprivate let preferredAuthMethods: [AuthMethod]
    fileprivate let domainName: String
    
    fileprivate let ssl: Validation
    fileprivate let tls: Validation
    
    fileprivate var socket: SMTPSocket
    
    fileprivate var state: State
    fileprivate var loggedIn: Bool
    
    fileprivate var secure: Bool = false
    
    fileprivate var features: Feature?
    
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
            case .authFailed: message = "authorization failed"
            case .authNotSupported: message = "no form of authorization supported"
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
    
    struct Feature {
        let data: [String: Any]
        init(_ data: [String: Any]) {
            self.data = data
        }
    }
    
    init(hostName: String, user: String?, password: String?,
         port: Port? = nil, ssl: Validation = defaultValidation, tls: Validation = defaultValidation,
         domainName: String = Host.current().name ?? "localhost",
         authMethods: [AuthMethod] = [.plain, .cramMD5, .login, .xOauth2]) throws
    {
        self.hostName = hostName
        self.user = user
        self.password = password
        self.preferredAuthMethods = authMethods
        self.domainName = domainName
        
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
    
    func updateFeatures(_ s: String) {
        features = s.featureDictionary()
    }
}

/// SMTP Operation
extension SMTP {
    func connect() throws -> SMTPResponse {
        self.state = .connecting
        
        let response = try socket.connect(servername: hostName)
        guard response.code == .serviceReady else {
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
    
    func send(_ string: String, expectedCodes: [SMTPReplyCode]) throws -> SMTPResponse {
        guard state == .connected else {
            try close()
            let error = SMTPError.noConnection
            logError(error: error, message: "no connection has been established")
            throw error
        }
        
        let response = try socket.send(string + CRLF)
        guard expectedCodes.contains(response.code) else {
            let error = SMTPError.badResponse
            logError(error: error, message: "\(error.description) on command: \(string), response: \(response.message)")
            throw error
        }
        
        return response
    }
    
    func send(_ command: SMTPCommand) throws -> SMTPResponse {
        return try send(command.text, expectedCodes: command.expectedCodes)
    }
    
    func login() throws {
        try sayHello()
        guard let features = features else {
            let error = SMTPError.unknown
            logError(error: error, message: "\(error.description) Unknown error happens when login. EHLO and HELO failed.")
            throw error
        }

        guard let method = (preferredAuthMethods.first { features.supported(auth: $0) }) else {
            let error = SMTPError.authNotSupported
            logError(error: error, message: "\(error.description)")
            throw error
        }
        
        let loginResult: SMTPResponse
        switch method {
        case .cramMD5:
            let response = try send(.auth(.cramMD5, ""))
            let challenge = response.message
            let responseToChallenge = try CryptoEncoder.cramMD5(challenge: challenge, user: user ?? "", password: password ?? "")
            loginResult = try send(.authResponse(.cramMD5, responseToChallenge))
        case .login: break
        case .plain: break
        case .xOauth2: break
        }
        
        if loginResult.code == .authSucceeded {
            loggedIn = true
        } else {
            let error = SMTPError.authFailed
            logError(error: error, message: "\(error.description)")
            throw error
        }
    }
    
    func sayHello() throws {
        if features != nil { return }
        // First, try ehlo to see whether it is supported.
        do { _ = try ehlo() }
        // If not, try helo
        catch { _ = try helo() }
    }
    
    func close() throws {
        try socket.close()
        state = .notConnected
        loggedIn = (user != nil && password != nil) ? false : true
        secure = false
    }
}

/// SMTP Commands
extension SMTP {
    func helo() throws -> SMTPResponse {
        let response = try send(.helo(domainName))
        updateFeatures(response.data)
        return response
    }
    
    func ehlo() throws -> SMTPResponse {
        let response = try send(.ehlo(domainName))
        updateFeatures(response.data)
        if tls.enabled && !secure {
            try starttls()
            return try ehlo()
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
}

extension String {
    static let featureMather = try! NSRegularExpression(pattern: "^(?:\\d+[\\-=]?)\\s*?([^\\s]+)(?:\\s+(.*)\\s*?)?$", options: [])
    
    func featureDictionary() -> SMTP.Feature {
        
        var feature = [String: Any]()
        
        let entries = replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n")
        entries.forEach {entry in
            let match = String.featureMather.groups(in: entry)
            if match.count == 2 {
                feature[match[0].lowercased()] = match[1].uppercased()
            } else if match.count == 1 {
                feature[match[0].lowercased()] = true
            }
        }
        return SMTP.Feature(feature)
    }
}

extension SMTP.Feature {
    func supported(auth: SMTP.AuthMethod) -> Bool {
        if let supported = data["auth"] as? String {
            return supported.contains(auth.rawValue)
        }
        return false
    }
}
