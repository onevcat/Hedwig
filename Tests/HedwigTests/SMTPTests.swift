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
    
    var smtp: SMTP!
    
    override func setUp() {
        if smtp != nil {
            try? smtp.close()
        }
        let ssl: Validation = (enabled: true, certificate: .defaults, cipher: .compat, protocols: [.all])
        smtp = try! SMTP(hostName: "smtp.zoho.com", user: nil, password: nil, ssl: ssl, domainName: "onevcat.com")
    }
    
    func testSMTPConnect() {
        
        do {
            let res = try smtp.connect()
            
            XCTAssertEqual(res.code, .serviceReady)
            XCTAssertTrue(res.message.contains("mx.zohomail.com"))
        } catch {
            XCTFail("Should not catch an error, but got \(error)")
        }

        XCTAssertNoThrows(try smtp.close())
    }
    
    func testSMTPCannotConnect() {
        XCTAssertThrowsError(
            try SMTP(hostName: "nosuchsite.org", user: nil, password: nil),
            "Unsupported host name should fail."
        )
    }
    
    func testSMTPSendHelo() {
        do {
            _ = try smtp.connect()
            let res = try smtp.helo()
            XCTAssertEqual(res.code, .commandOK)
            XCTAssertTrue(res.message.contains("onevcat.com"))
        } catch {
            XCTFail("Should not catch an error, but got \(error)")
        }
    }
    
    func testSMTPSendEhlo() {
        do {
            _ = try smtp.connect()
            let res = try smtp.ehlo()
            XCTAssertEqual(res.code, .commandOK)
            XCTAssertTrue(res.data.contains("onevcat.com"))
        } catch {
            XCTFail("Should not catch an error, but got \(error)")
        }
    }
    
    static var allTests : [(String, (SMTPTests) -> () throws -> Void)] {
        return [
            ("testSMTPConnect", testSMTPConnect),
            ("testSMTPCannotConnect", testSMTPCannotConnect),
            ("testSMTPSendHelo", testSMTPSendHelo),
            ("testSMTPSendEhlo", testSMTPSendEhlo)
        ]
    }
}
