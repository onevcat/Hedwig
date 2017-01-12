//
//  MailTests.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/5.
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

import XCTest
import Foundation
@testable import Hedwig

class MailTests: XCTestCase {
    
    func testCanInitMail() {
        _ = Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Hello")
    }
    
    func testMailPropertiesCorrect() {
        
        let a1 = Attachment(filePath: "")
        let a2 = Attachment(htmlContent: "<html></html>", alternative: true)
        
        let mail = Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", cc: "Wei Wang <hello@world.com>, foo1@bar.com", bcc: "<foo2@bar.com>", subject: "Mail Subject", attachments: [a1, a2], additionalHeaders: ["test-key": "test-value"])
        
        XCTAssertEqual(mail.from?.name, "")
        XCTAssertEqual(mail.from?.address, "onev@onevcat.com")
        
        XCTAssertEqual(mail.to.count, 1)
        XCTAssertEqual(mail.to[0].name, "")
        XCTAssertEqual(mail.to[0].address, "foo@bar.com")
        
        XCTAssertEqual(mail.cc!.count, 2)
        XCTAssertEqual(mail.cc![0].name, "Wei Wang")
        XCTAssertEqual(mail.cc![0].address, "hello@world.com")
        XCTAssertEqual(mail.cc![1].name, "")
        XCTAssertEqual(mail.cc![1].address, "foo1@bar.com")
        
        XCTAssertEqual(mail.bcc!.count, 1)
        XCTAssertEqual(mail.bcc![0].name, "")
        XCTAssertEqual(mail.bcc![0].address, "foo2@bar.com")
        
        XCTAssertEqual(mail.subject, "Mail Subject")
        
        XCTAssertEqual(mail.alternative, a2)
        XCTAssertEqual(mail.attachments, [a1])
        
        XCTAssertEqual(mail.additionalHeaders, ["test-key": "test-value"])
    }
    
    func testMailInvalid() {
        let mail = Mail(text: "", from: "onev@onevcat", to: "", subject: "")
        XCTAssertFalse(mail.hasRecipient)
        
        let anotherMail = Mail(text: "", from: "", to: "onev@onevcat", subject: "")
        XCTAssertFalse(anotherMail.hasSender)
    }
    
    func testHeaderDateFormat() {
        let date = Date(timeIntervalSince1970: 0)
        let formatter = DateFormatter.smtpDateFormatter
        formatter.timeZone = TimeZone(secondsFromGMT: 3600 * 9)
        XCTAssertEqual(formatter.string(from: date), "Thu, 1 Jan 1970 09:00:00 +0900")
    }
    
    static var allTests : [(String, (MailTests) -> () throws -> Void)] {
        return [
            ("testCanInitMail", testCanInitMail),
            ("testMailPropertiesCorrect", testMailPropertiesCorrect),
            ("testMailInvalid", testMailInvalid),
            ("testHeaderDateFormat", testHeaderDateFormat)
        ]
    }
}
