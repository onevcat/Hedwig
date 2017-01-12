//
//  HedeigTests.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/9.
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

import XCTest
import Hedwig

class HedwigTests: XCTestCase {
    
    var hedwig: Hedwig!
    
    override func setUp() {
        hedwig = Hedwig(hostName: "onevcat.com", user: "foo@bar.com", password: "password", port: 2255, secure: .plain)
    }
    
    func testCanSendMail() {
        
        let e = expectation(description: "wait")

        let plainMail = Mail(text: "Hello World", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title")
        hedwig.send(plainMail) { error in
            if error != nil { XCTFail("Should no error happens, but \(error)") }
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func testCanSendMailWithAttachment() {
        let e = expectation(description: "wait")
    
        let attachement = Attachment(htmlContent: "<html></html>")
        let mail = Mail(text: "Hello World", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title", attachments: [attachement])
        hedwig.send(mail) { error in
            if error != nil { XCTFail("Should no error happens, but \(error)") }
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func testCanSendMultipleMails() {
        let e = expectation(description: "wait")
        let mail1 = Mail(text: "Hello World", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title")
        let mail2 = Mail(text: "Hello World Again", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title")
        
        var count = 0
        hedwig.send([mail1, mail2], progress: { result in
            XCTAssertNil(result.1)
            count += 1
        }) { sent, failed in
            if !failed.isEmpty {
                XCTFail("Should no error happens, but failed mails: \(failed)")
            }
            XCTAssertEqual(count, 2)
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    static var allTests : [(String, (HedwigTests) -> () throws -> Void)] {
        return [
            ("testCanSendMail", testCanSendMail),
            ("testCanSendMailWithAttachment", testCanSendMailWithAttachment),
            ("testCanSendMultipleMails", testCanSendMultipleMails)
        ]
    }
}
