//
//  MailTests.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/5.
//
//

import XCTest
@testable import Hedwig

class MailTests: XCTestCase {
    
    func testCanInitMail() {
        _ = try! Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Hello")
    }
    
    func testMailPropertiesCorrect() {
        
        let a1 = Attachment(filePath: "")
        let a2 = Attachment(htmlContent: "<html></html>", alternative: true)
        
        let mail = try! Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", cc: "Wei Wang <hello@world.com>, foo1@bar.com", bcc: "<foo2@bar.com>", subject: "Mail Subject", attachments: [a1, a2], additionalHeaders: ["test-key": "test-value"])
        
        XCTAssertEqual(mail.from.name, "")
        XCTAssertEqual(mail.from.address, "onev@onevcat.com")
        
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
    
    func testMailCreatingFail() {
        XCTAssertThrowsError(try Mail(text: "", from: "onev@onevcat", to: "", subject: nil), "Should throw noRecipient error") { (error) in
            XCTAssertEqual(error as? MailError, MailError.noRecipient)
        }
        
        XCTAssertThrowsError(try Mail(text: "", from: "", to: "onev@onevcat", subject: nil), "Should throw noSender error") { (error) in
            XCTAssertEqual(error as? MailError, MailError.noSender)
        }
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
            ("testMailCreatingFail", testMailCreatingFail)
        ]
    }
}
