//
//  SMTPResponse.swift
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

struct SMTPResponse {
    
    static let matcher = try! Regex(pattern: "^(\\d+)\\s+(.*)$", options: [])
    
    let code: SMTPReplyCode
    let message: String
    let data: String
    
    init(string: String) throws {
        let parsed = SMTPResponse.matcher.groups(in: string)
        guard parsed.count == 2, let code = Int(parsed[0]) else {
            throw SMTP.SMTPError.badResponse
        }
        
        self.code = SMTPReplyCode(code)
        message = parsed[1]
        data = string
    }
    
    init(code: SMTPReplyCode, data: String) {
        self.code = code
        self.data = data
        self.message = ""
    }
}
