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
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(try! SMTP().connect(), true)
    }
    
    
    static var allTests : [(String, (SMTPTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
