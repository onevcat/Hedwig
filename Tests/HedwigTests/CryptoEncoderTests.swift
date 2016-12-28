//
//  CryptoEncoderTests.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/28.
//
//

import Foundation

import XCTest
@testable import Hedwig

class CryptoEncoderTests: XCTestCase {

    func testCramMD5Encode() {
        let user = "foo@bar.com"
        let password = "123"
        let challenge = "aGVsbG8="
        
        // Calculated by http://busylog.net/cram-md5-online-generator/
        let expected = "Zm9vQGJhci5jb20gNGVlNzU0OTlkMjlhZGZjNThiZTM0NmY2MmY1ZmNmMTE="
        
        do {
            let result = try CryptoEncoder.cramMD5(challenge: challenge, user: user, password: password)
            XCTAssertEqual(result, expected)
        } catch {
            XCTFail("Should be no error.")
        }
    }
    
    static var allTests : [(String, (CryptoEncoderTests) -> () throws -> Void)] {
        return [
            ("testCramMD5Encode", testCramMD5Encode)
        ]
    }
}

