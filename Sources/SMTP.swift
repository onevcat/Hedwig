//
//  SMTP.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
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

private func logError(_ error: SMTP.SMTPError, message: String? = nil) {
    let message = message ?? ""
    print("[Hedwig] SMTP Error: \(error). \(message)")
}

private func logWarning(message: String? = nil) {
    let message = message ?? ""
    print("[Hedwig] SMTP Warning: \(message)")
}


/// SMTP Port number
public typealias Port = UInt16

/// Represents an remote SMTP. Do not use this type directly. Use `Hedwig` to
/// send mails instead.
public class SMTP {
    let hostName: String
    fileprivate let port: Port
    fileprivate let user: String?
    fileprivate let password: String?
    fileprivate let preferredAuthMethods: [AuthMethod]
    fileprivate let domainName: String
    fileprivate let secure: Secure
    fileprivate var socket: SMTPSocket
    fileprivate(set) var state: State
    fileprivate(set) var loggedIn: Bool
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
         port: Port? = nil, secure: Secure = .tls,
         validation: Validation = .default, domainName: String = "localhost",
         authMethods: [AuthMethod] = [.plain, .cramMD5, .login, .xOauth2]) throws
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
            let sock = try TCPClient(hostName: hostName, port: self.port)
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
    
    deinit {
        if state != .notConnected {
            try? close()
        }
    }
    
    func updateFeatures(_ s: String) {
        features = s.featureDictionary()
    }
}

extension SMTP {
    
    /// Represents SMTP validation methods.
    public struct Validation {
        
        /// Certificate used when connecting to 
        /// SMTP server through a secure layer.
        public let certificate: Certificates
        
        /// Cipher used when connecting to SMTP.
        public let cipher: Config.Cipher
        
        /// Protocols supported when connecting to SMTP.
        public let protocols: [Config.TLSProtocol]
        
        /// Initilize a validation instance.
        ///
        /// - Parameters:
        ///   - certificate: Certificate used when connecting to
        ///                  SMTP server through a secure layer.
        ///   - cipher: Cipher used when connecting to SMTP.
        ///   - protocols: Protocols supported when connecting to SMTP.
        public init(certificate: Certificates,
                    cipher: Config.Cipher,
                    protocols: [Config.TLSProtocol])
        {
            self.certificate = certificate
            self.cipher = cipher
            self.protocols = protocols
        }
        
        /// Default `Validation` instance, with default certificate, 
        /// compat cipher and all protocols supporting.
        public static let `default` = Validation(certificate: .defaults,
                                                 cipher: .compat,
                                                 protocols: [.all])
    }
}

extension SMTP {
    
    /// Error while SMTP connecting and communicating.
    public enum SMTPError: Error, CustomStringConvertible {
        /// Could not connect to remote server.
        case couldNotConnect
        /// Connecting to SMTP server time out
        case timeOut
        /// The response of SMTP server is bad and not expected.
        case badResponse
        /// No connection has been established
        case noConnection
        /// Authorization failed
        case authFailed
        /// Can not authorizate since target server not support EHLO
        case authNotSupported
        /// No form of authorization methos supported
        case authUnadvertised
        /// Connection is closed by remote
        case connectionClosed
        /// Connection is already ended
        case connectionEnded
        /// Connection auth failed
        case connectionAuth
        /// Unknown error
        case unknown
        
        /// A human-readable description of SMTP error.
        public var description: String {
            let message: String
            switch self {
            case .couldNotConnect:
                message = "could not connect to SMTP server"
            case .timeOut:
                message = "connecting to SMTP server time out"
            case .badResponse:
                message = "bad response"
            case .noConnection:
                message = "no connection has been established"
            case .authFailed:
                message = "authorization failed"
            case .authUnadvertised:
                message = "can not authorizate since target server not support EHLO"
            case .authNotSupported:
                message = "no form of authorization supported"
            case .connectionClosed:
                message = "connection is closed by remote"
            case .connectionEnded:
                message = "connection is ended"
            case .connectionAuth:
                message = "connection auth failed"
            case .unknown:
                message = "unknown error"
            }
            return message
        }
    }
}

extension SMTP {
    /// Secrity layer used when connencting an SMTP server.
    public enum Secure {
        /// No encryped. If the server supports STARTTLS, the layer will be 
        /// upgraded automatically.
        case plain
        /// Secure Sockets Layer.
        case ssl
        /// Transport Layer Security. If the server supports STARTTLS, the
        /// layer will be upgraded automatically.
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
    /// Auth method to an SMTP server.
    ///
    /// - plain: Plain authorization.
    /// - cramMD5: CRAM-MD5 authorization.
    /// - login: Login authorization.
    /// - xOauth2: xOauth2 authorization.
    public enum AuthMethod: String {
        /// Plain authorization.
        case plain = "PLAIN"
        /// CRAM-MD5 authorization.
        case cramMD5 = "CRAM-MD5"
        /// Login authorization.
        case login = "LOGIN"
        /// xOauth2 authorization.
        case xOauth2 = "XOAUTH2"
    }
}


/// SMTP Operation
extension SMTP {
    func connect() throws -> SMTPResponse {
        
        guard state == .notConnected else {
            _ = try quit()
            return try connect()
        }
        
        self.state = .connecting
        
        let response = try socket.connect(servername: hostName)
        guard response.code == .serviceReady else {
            let error = SMTPError.badResponse
            logError(error, message: "\(error.description) on connecting: \(response.message)")
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
            logError(error, message: "no connection has been established")
            throw error
        }
        
        let response = try socket.send(string)
        guard expectedCodes.contains(response.code) else {
            let error = SMTPError.badResponse
            logError(error, message: "\(error.description) on command: \(string), response: \(response.message)")
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
            logError(error, message: "\(error.description) Unknown error happens when login. EHLO and HELO failed.")
            throw error
        }
        
        guard let user = user, let password = password else {
            let error = SMTPError.authFailed
            logError(error, message: "\(error.description) User name or password is not supplied.")
            throw error
        }

        guard let method = (preferredAuthMethods.first { features.supported(auth: $0) }) else {
            let error = SMTPError.authNotSupported
            logError(error, message: "\(error.description)")
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
            loginResult = try send(.auth(.xOauth2, CryptoEncoder.xOauth2(user: user, password: password)))
        }
        
        if loginResult.code == .authSucceeded {
            loggedIn = true
        } else if loginResult.code == .authFailed {
            let error = SMTPError.authFailed
            logError(error, message: "\(error.description)")
            throw error
        } else {
            let error = SMTPError.authUnadvertised
            logError(error, message: "\(error.description)")
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
    
    func message(bytes: [UInt8]) throws {
        try socket.sock.send(bytes: bytes)
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
    
    func help(args: String? = nil) throws -> SMTPResponse {
        return try send(.help(args))
    }
    
    func rset() throws -> SMTPResponse {
        return try send(.rset)
    }
    
    func noop() throws -> SMTPResponse {
        return try send(.noop)
    }
    
    func mail(from: String) throws -> SMTPResponse {
        return try send(.mail(from))
    }
    
    func rcpt(to: String) throws -> SMTPResponse {
        return try send(.rcpt(to))
    }
    
    func data() throws -> SMTPResponse {
        return try send(.data)
    }
    
    func dataEnd() throws -> SMTPResponse {
        return try send(.dataEnd)
    }
    
    func vrfy(address: String) throws -> SMTPResponse {
        return try send(.vrfy(address))
    }
    
    func expn(address: String) throws -> SMTPResponse {
        return try send(.expn(address))
    }
    
    func quit() throws -> SMTPResponse {
        defer { try? close() }
        let response = try send(.quit)
        return response
    }
}

extension String {
    static let featureMather = try! Regex(pattern: "^(?:\\d+[\\-=]?)\\s*?([^\\s]+)(?:\\s+(.*)\\s*?)?$", options: [])
    
    func featureDictionary() -> SMTP.Feature {
        
        var feature = [String: Any]()
        
        // Linux replacingOccurrences will fail when there is \r in string.
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
