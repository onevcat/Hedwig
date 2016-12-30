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

    func testCramMD5Encoding() {
        let user = "foo@bar.com"
        let password = "password"
        let challenge = "aGVsbG8="
        
        // Calculated by http://busylog.net/cram-md5-online-generator/
        let expected = "Zm9vQGJhci5jb20gMjhmOGNhMDI0YjBlNjE4YWUzNWQ0NmRiODExNzU2NjM="
        
        do {
            let result = try CryptoEncoder.cramMD5(challenge: challenge, user: user, password: password)
            XCTAssertEqual(result, expected)
        } catch {
            XCTFail("Should be no error.")
        }
    }
    
    func testPlainEncoding() {
        let user = "foo@bar.com"
        let password = "password"

        // echo -ne "\0foo@bar.com\0password"|base64
        let expected = "AGZvb0BiYXIuY29tAHBhc3N3b3Jk"
        let result = CryptoEncoder.plain(user: user, password: password)
        XCTAssertEqual(result, expected)
    }
    
    func testLoginEncoding() {
        let user = "foo@bar.com"
        let password = "password"
        
        let expected = ("Zm9vQGJhci5jb20=", "cGFzc3dvcmQ=")
        let result = CryptoEncoder.login(user: user, password: password)
        XCTAssertEqual(result.encodedUser, expected.0)
        XCTAssertEqual(result.encodedPassword, expected.1)
    }
    
    func testOauth2Encoding() {
        // https://developers.google.com/gmail/xoauth2_protocol
        let user = "foo@bar.com"
        let token = "token"
        
        // echo -ne "user=foo@bar.com\001auth=Bearer token\001\001"|base64
        let expected = "dXNlcj1mb29AYmFyLmNvbQFhdXRoPUJlYXJlciB0b2tlbgEB"
        let result = CryptoEncoder.xOauth2(user: user, password: token)
        XCTAssertEqual(result, expected)
    }
    
    static var allTests : [(String, (CryptoEncoderTests) -> () throws -> Void)] {
        return [
            ("testCramMD5Encoding", testCramMD5Encoding),
            ("testPlainEncoding", testPlainEncoding),
            ("testLoginEncoding", testLoginEncoding),
            ("testOauth2Encoding", testOauth2Encoding)
        ]
    }
}

