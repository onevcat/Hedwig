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
    let message = message ?? ""
    print("[Hedwig] SMTP Error: \(error). \(message)")
}

private func logWarning(message: String? = nil) {
    let message = message ?? ""
    print("[Hedwig] SMTP Warning: \(message)")
}


typealias Port = UInt16

class SMTP {
    fileprivate let hostName: String
    fileprivate let port: Port
    fileprivate let user: String?
    fileprivate let password: String?
    fileprivate let preferredAuthMethods: [AuthMethod]
    fileprivate let domainName: String
    fileprivate let secure: Secure
    fileprivate var socket: SMTPSocket
    fileprivate var state: State
    fileprivate var loggedIn: Bool
    fileprivate var features: Feature?
    fileprivate let validation: Validation

    fileprivate var secureConnected = false
    
    struct Feature {
        let data: [String: Any]
        init(_ data: [String: Any]) {
            self.data = data
        }
    }
    
    init(hostName: String, user: String?, password: String?,
         port: Port? = nil, secure: Secure = .tls, validation: Validation = .default,
         domainName: String = "", authMethods: [AuthMethod] = [.plain, .cramMD5, .login, .xOauth2]) throws
    {
        self.hostName = hostName
        self.user = user
        self.password = password
        self.preferredAuthMethods = authMethods
        self.domainName = domainName
        
        self.port = port ?? secure.port
        self.secure = secure
        
        self.loggedIn = (user != nil && password != nil) ? false : true
        self.state = .notConnected
        self.validation = validation
        
        if secure == .plain || secure == .tls {
            let address = InternetAddress(hostname: hostName, port: self.port)
            let sock = try TCPClient(address: address)
            self.socket = SMTPSocket(sock: sock)
        } else {
            let sock = try TLS.Socket(mode: .client,
                                      hostname: hostName,
                                      port: self.port,
                                      certificates: validation.certificate,
                                      cipher: validation.cipher,
                                      proto: validation.protocols)
            self.socket = SMTPSocket(sock: sock)
        }
    }
    
    func updateFeatures(_ s: String) {
        features = s.featureDictionary()
    }
}

extension SMTP {
    struct Validation {
        let certificate: Certificates
        let cipher: Config.Cipher
        let protocols: [Config.TLSProtocol]
        
        static let `default` = Validation(certificate: .defaults, cipher: .compat, protocols: [.all])
    }
}

extension SMTP {
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
}

extension SMTP {
    enum Secure {
        case plain
        case ssl
        case tls
        
        var port: Port {
            switch self {
            case .plain: return 25
            case .ssl: return 465
            case .tls: return 587
            }
        }
    }
}

extension SMTP {
    enum State {
        case notConnected
        case connecting
        case connected
    }
}

extension SMTP {
    enum AuthMethod: String {
        case plain = "PLAIN"
        case cramMD5 = "CRAM-MD5"
        case login = "LOGIN"
        case xOauth2 = "XOAUTH2"
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
        if secure == .ssl {
            secureConnected = true
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
        
        let response = try socket.send(string)
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
        
        guard let user = user, let password = password else {
            let error = SMTPError.authFailed
            logError(error: error, message: "\(error.description) User name or password is not supplied.")
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
            let responseToChallenge = try CryptoEncoder.cramMD5(challenge: challenge, user: user, password: password)
            loginResult = try send(.authResponse(.cramMD5, responseToChallenge))
        case .login:
            _ = try send(.auth(.login, ""))
            let identify = CryptoEncoder.login(user: user, password: password)
            _ = try send(.authUser(identify.encodedUser))
            loginResult = try send(.authResponse(.login, identify.encodedPassword))
        case .plain:
            loginResult = try send(.auth(.plain, CryptoEncoder.plain(user: user, password: password)))
        case .xOauth2:
            loginResult = try send(.auth(.xOauth2, CryptoEncoder.xOath2(user: user, password: password)))
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
        secureConnected = false
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
        
        if !secureConnected {
            if features?.canStartTLS ?? false {
                try starttls()
                secureConnected = true
                return try ehlo()
            } else {
                logWarning(message: "Using plain SMTP and server does not support STARTTLS command. It is not recommended to submit information to this server!")
            }
        }
        
        return response
    }
    
    func starttls() throws {
        _ = try send(.starttls)
        let sock = try TLS.Socket(existing: socket.sock.internalSocket,
                               certificates: validation.certificate,
                               cipher: validation.cipher,
                               proto: validation.protocols,
                               hostName: hostName)
        socket = SMTPSocket(sock: sock)
        secureConnected = true
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
    
    func supported(_ key: String) -> Bool {
        guard let result = data[key.lowercased()] else {
            return false
        }
        return result as? Bool ?? false
    }
    
    func value(for key: String) -> String? {
        return data[key.lowercased()] as? String
    }
    
    var canStartTLS: Bool {
        return supported("STARTTLS")
    }
}
