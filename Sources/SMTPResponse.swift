//
//  SMTPResponse.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/28.
//
//

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
