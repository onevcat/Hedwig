//
//  SMTPTests.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//

import XCTest
@testable import Hedwig

class SMTPTests: XCTestCase {
    func testSMTPConnect() {
        var smtp = SMTP(hostName: "smtp.zoho.com", user: nil, password: nil)
        XCTAssertNoThrows(try smtp.connect())
        XCTAssertNoThrows(try smtp.close())
    }
    
    
    static var allTests : [(String, (SMTPTests) -> () throws -> Void)] {
        return [
            ("testExample", testSMTPConnect),
        ]
    }
}
