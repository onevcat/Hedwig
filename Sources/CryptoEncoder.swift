//
//  CryptoEncoder.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/28.
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
import HMAC

struct CryptoEncoder {
    static func cramMD5(challenge: String, user: String, password: String)
        throws -> String
    {
        let hmac = HMAC(.md5, challenge.bytes.base64Decoded.string.toBytes())
        let result = try hmac.authenticate(key: password.toBytes()).hexString
        return (user + " " + result).base64EncodedString
    }
    
    static func login(user: String, password: String) ->
        (encodedUser: String, encodedPassword: String)
    {
        return (user.base64EncodedString, password.base64EncodedString)
    }
    
    static func plain(user: String, password: String) -> String {
        let text = "\u{0000}\(user)\u{0000}\(password)"
        return text.base64EncodedString
    }
    
    static func xOauth2(user: String, password: String) -> String {
        let text = "user=\(user)\u{0001}auth=Bearer \(password)\u{0001}\u{0001}"
        return text.base64EncodedString
    }
}

extension String {
    var base64EncodedString: String {
        return Data(utf8).base64EncodedString()
    }
}
