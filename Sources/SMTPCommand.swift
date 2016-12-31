//
//  SMTPCommand.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//

import Foundation

enum SMTPCommand {
    /// helo(domain: String)
    case helo(String)
    /// ehlo(domain: String)
    case ehlo(String)
    case starttls
    /// help(args: String)
    case help(String?)
    case rset
    case noop
    /// mail(from: String)
    case mail(String)
    /// rcpt(to: String)
    case rcpt(String)
    case data
    case dataEnd
    /// verify(address: String)
    case vrfy(String)
    /// expn(String)
    case expn(String)
    /// auth(method: String, body: String)
    case auth(SMTP.AuthMethod, String)
    case authResponse(SMTP.AuthMethod, String)
    case authUser(String)
    case quit
}

extension SMTPCommand {
    
    static let validAuthCodes: [SMTPReplyCode] = [.authSucceeded, .authNotAdvertised, .authFailed]
    
    var text: String {
        switch self {
        case .helo(let domain):
            return "HELO \(domain)"
        case .ehlo(let domain):
            return "EHLO \(domain)"
        case .starttls:
            return "STARTTLS"
        case .help(let args):
            return args != nil ? "HELP \(args!)" : "HELP"
        case .rset:
            return "RSET"
        case .noop:
            return "NOOP"
        case .mail(let from):
            return "MAIL FROM: \(from)"
        case .rcpt(let to):
            return "RCPT TO: \(to)"
        case .data:
            return "DATA"
        case .dataEnd:
            return "\(CRLF)."
        case .vrfy(let address):
            return "VRFY \(address)"
        case .expn(let address):
            return "EXPN \(address)"
        case .auth(let method, let body):
            return "AUTH \(method.rawValue) \(body)"
        case .authUser(let body):
            return body
        case .authResponse(let method, let body):
            switch method {
            case .cramMD5: return body
            case .login: return body
            default: fatalError("Can not response to a challenge.")
            }
        case .quit:
            return "QUIT"
        }
    }
    
    var expectedCodes: [SMTPReplyCode] {
        switch self {
        case .starttls:
            return [.serviceReady]
        case .auth(let method, _):
            switch method {
            case .cramMD5: return [.containingChallenge]
            case .login:   return [.containingChallenge]
            case .plain:   return SMTPCommand.validAuthCodes
            case .xOauth2: return SMTPCommand.validAuthCodes
            }
        case .authUser(_):
            return [.containingChallenge]
        case .authResponse(let method, _):
            switch method {
            case .cramMD5: return SMTPCommand.validAuthCodes
            case .login:   return SMTPCommand.validAuthCodes
            default: fatalError("Can not response to a challenge.")
            }
        case .help(_):
            return [.systemStatus, .helpMessage]
        case .rcpt(_):
            return [.commandOK, .willForward]
        case .vrfy(_):
            return [.commandOK, .willForward, .forAttempt]
        case .quit:
            return [.connectionClosing, .commandOK]
        default:
            return [.commandOK]
        }
    }
}

struct SMTPReplyCode: Equatable {
    
    let rawValue: Int
    init(_ value: Int) {
        rawValue = value
    }

    static let systemStatus = SMTPReplyCode(211)
    static let helpMessage = SMTPReplyCode(214)
    static let serviceReady = SMTPReplyCode(220)
    static let connectionClosing = SMTPReplyCode(221)
    static let authSucceeded = SMTPReplyCode(235)
    static let commandOK = SMTPReplyCode(250)
    static let willForward = SMTPReplyCode(251)
    static let forAttempt = SMTPReplyCode(252)
    static let containingChallenge = SMTPReplyCode(334)
    static let authNotAdvertised = SMTPReplyCode(503)
    static let authFailed = SMTPReplyCode(535)
    
    public static func ==(lhs: SMTPReplyCode, rhs: SMTPReplyCode) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
