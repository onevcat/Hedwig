//
//  CryptoEncoder.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/28.
//
//

import Foundation
import HMAC

struct CryptoEncoder {
    static func cramMD5(challenge: String, user: String, password: String) throws -> String {
        let hmac = HMAC(.md5, challenge.base64DecodedString.toBytes())
        let result = try hmac.authenticate(key: password.toBytes()).hexString
        return (user + " " + result).base64EncodedString
    }
    
    static func login(user: String, password: String) -> (encodedUser: String, encodedPassword: String) {
        return (user.base64DecodedString, password.base64EncodedString)
    }
    
    static func plain(user: String, password: String) -> String {
        let text = "\u{0000}\(user)\u{0000}\(password)"
        return text.base64EncodedString
    }
    
    static func xOath2(user: String, password: String) -> String {
        let text = "user=\(user)\u{0001}auth=Bearer \(password)\u{0001}\u{0001}"
        return text.base64EncodedString
    }
}

extension String {
    var base64EncodedString: String {
        return Data(utf8).base64EncodedString()
    }
}
