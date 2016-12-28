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
        return Data((user + " " + result).utf8).base64EncodedString()
    }
}
