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
    /// help(args: String)
    case starttls
    case help(String)
    case rset
    case noop
    /// mail(from: String)
    case mail(String)
    /// rcpt(to: String)
    case rcpt(String)
    case data
    case dataEnd
    /// verify(address: String)
    case verify(String)
    /// expn(String)
    case expn(String)
}

extension SMTPCommand {
    var text: String {
        switch self {
        case .helo(let domain):
            return "helo \(domain)"
        case .ehlo(let domain):
            return "ehlo \(domain)"
        case .starttls:
            return "starttls"
        default:
            return ""
        }
    }
    
    var expectedCodes: [Int] {
        switch self {
        case .starttls:
            return [220]
        default:
            return [250]
        }
    }
}
