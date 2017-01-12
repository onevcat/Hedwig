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
        hedwig.send([mail1, mail2], progress: { mail, error in
            XCTAssertNil(error)
            count += 1
        }) { sent, failed in
            if !failed.isEmpty {
                XCTFail("Should no error happens, but failed")
                for (mail, error) in failed {
                    print("Mail \(mail.messageId) errored: \(error)")
                }
            }
            XCTAssertEqual(count, 2)
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func testNoSenderMailWillNotBeSent() {
        let e = expectation(description: "wait")
        let mailWithoutSender = Mail(text: "Hello", from: "", to: "foo@bar.com")
        hedwig.send(mailWithoutSender) { (error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error as? MailError, MailError.noSender)
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func testNoRecipientMailWillNotBeSent() {
        let e = expectation(description: "wait")
        let mailWithoutRecipient = Mail(text: "Hello", from: "foo@bar.com", to: "")
        
        hedwig.send(mailWithoutRecipient) { (error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(error as? MailError, MailError.noRecipient)
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func testCanContinueSendingMailAfterFailing() {
        let e = expectation(description: "wait")
        let failMail = Mail(text: "Hello", from: "", to: "foo@bar.com")
        let mail = Mail(text: "Hello", from: "foo@bar.com", to: "foo@bar.com")
        
        hedwig.send([failMail, mail], progress: { (mail, error) in
            
        }) { (sent, failed) in
            XCTAssertEqual(sent.count, 1)
            XCTAssertEqual(failed.count, 1)
            XCTAssertEqual(sent.first!.messageId, mail.messageId)
            e.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }
    
    func testCanSendMailsConcurrency() {
        
        let e = expectation(description: "wait")
        
        let mail1 = Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com")
        let mail2 = Mail(text: "World", from: "foo@bar.com", to: "onev@onevcat.com")
        
        var mail1Finished = false
        var mail2Finished = false
        
        hedwig.send([mail1]) { (sent, failed) in
            XCTAssertEqual(sent.first!.messageId, mail1.messageId)
            mail1Finished = true
            if mail1Finished && mail2Finished {
                e.fulfill()
            }
        }
        
        hedwig.send([mail2]) { (sent, failed) in
            XCTAssertEqual(sent.first!.messageId, mail2.messageId)
            mail2Finished = true
            if mail1Finished && mail2Finished {
                e.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5)
    }

    static var allTests : [(String, (HedwigTests) -> () throws -> Void)] {
        return [
            ("testCanSendMail", testCanSendMail),
            ("testCanSendMailWithAttachment", testCanSendMailWithAttachment),
            ("testCanSendMultipleMails", testCanSendMultipleMails),
            ("testNoSenderMailWillNotBeSent", testNoSenderMailWillNotBeSent),
            ("testNoRecipientMailWillNotBeSent", testNoRecipientMailWillNotBeSent),
            ("testCanContinueSendingMailAfterFailing", testCanContinueSendingMailAfterFailing),
            ("testCanSendMailsConcurrency", testCanSendMailsConcurrency)
        ]
    }
}
