//
//  MailStreamTests.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/9.
//
//

import XCTest
@testable import Hedwig


class MailStreamTests: XCTestCase {

    func testCanStreamPlainMail() {
        let mail = try! Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com")
        let streamed = mail.streamedContent()
        let expected = mail.concatHeader(with: plainMail)
        XCTAssertEqual(streamed, expected)
    }
    
    func testCanStreamMailWithHTMLAttachment() {
        let html = Attachment(htmlContent: "<html></html>")
        let mail = try! Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title", attachments: [html])
        
        let streamed = mail.streamedContent()
        let expected = mail.concatHeader(with: htmlAttachmentMail)
        XCTAssertEqual(streamed.boundaryUnified, expected)
    }
    
    func testCanStreamMailWithFileAttachment() {
        let data = "{\"key\": \"hello world\"}".data(using: .utf8)
        let path = "/tmp/attachment.json"
        guard FileManager.default.createFile(atPath: path, contents: data, attributes: nil) else {
            XCTFail("Can not create file on /tmp folder.")
            return
        }
        
        let attachment = Attachment(filePath: path, inline: false, additionalHeaders: ["header-key": "header-value"])
        let mail = try! Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title", attachments: [attachment])
        
        let streamed = mail.streamedContent()
        let expected = mail.concatHeader(with: fileAttachementMail)
        XCTAssertEqual(streamed.boundaryUnified, expected)
    }
    
    func testCanStreamMailWithDataAttachment() {
        let data = "{\"key\": \"hello world\"}".data(using: .utf8)!
        let attachment = Attachment(data: data, mime: "application/zip", name: "file.zip", inline: true)
        let mail = try! Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title", attachments: [attachment])
        
        let streamed = mail.streamedContent()
        let expected = mail.concatHeader(with: dataAttachementMail)
        XCTAssertEqual(streamed.boundaryUnified, expected)
    }
    
    static var allTests : [(String, (MailStreamTests) -> () throws -> Void)] {
        return [
            ("testCanStreamPlainMail", testCanStreamPlainMail),
            ("testCanStreamMailWithHTMLAttachment", testCanStreamMailWithHTMLAttachment),
            ("testCanStreamMailWithFileAttachment", testCanStreamMailWithFileAttachment),
            ("testCanStreamMailWithDataAttachment", testCanStreamMailWithDataAttachment),
        ]
    }
}


extension Mail {
    func concatHeader(with content: String) -> String {
        let header = headersString + CRLF
        return header + content
    }
}

extension Mail {
    func streamedContent() -> String {
        var data = [UInt8]()
        let stream = MailStream(mail: self) { (bytes) in
            data.append(contentsOf: bytes)
        }
        try! stream.stream()
        
        return try! String(bytes: data)
    }
}

extension String {
    var boundaryUnified: String {
        var replaces = [String]()
        for i in 0 ..< boundaries.count {
            replaces.append("X\(i)")
        }
        
        var s = self
        for (replace, boundary) in zip(replaces, boundaries) {
            s = s.replacingOccurrences(of: boundary, with: replace)
        }
        
        return s
    }
    
    var boundaries: [String] {
        var result = [String]()
        let pattern = try! NSRegularExpression(pattern: "boundary=\"((.+?))\"", options: [])
        let matches = pattern.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
        
        for match in matches {
            let boundary = NSString(string: self).substring(with: (match.rangeAt(1)))
            result.append(boundary)
        }
        return result
    }
}

let plainMail = [
    "Content-Type: text/plain; charset=utf-8",
    "Content-Transfer-Encoding: 7bit",
    "Content-Disposition: inline",
    "",
    "Hello",
    CRLF
].joined(separator: CRLF)

let htmlAttachmentMail = [
    "Content-Type: multipart/mixed; boundary=\"X0\"",
    "",
    "--X0",
    "Content-Type: text/plain; charset=utf-8",
    "Content-Transfer-Encoding: 7bit",
    "Content-Disposition: inline",
    "",
    "Hello",
    "",
    "--X0",
    "CONTENT-TYPE: text/html; charset=utf-8",
    "CONTENT-DISPOSITION: inline",
    "CONTENT-TRANSFER-ENCODING: BASE64",
    "PGh0bWw+PC9odG1sPg==",
    "--X0--",
    CRLF
].joined(separator: CRLF)

let fileAttachementMail = [
    "Content-Type: multipart/mixed; boundary=\"X0\"",
    "",
    "--X0",
    "Content-Type: text/plain; charset=utf-8",
    "Content-Transfer-Encoding: 7bit",
    "Content-Disposition: inline",
    "",
    "Hello",
    "",
    "--X0",
    "CONTENT-DISPOSITION: attachment; filename=\"=?UTF-8?Q?attachment.json?=\"",
    "CONTENT-TRANSFER-ENCODING: BASE64",
    "HEADER-KEY: header-value",
    "CONTENT-TYPE: application/json",
    "eyJrZXkiOiAiaGVsbG8gd29ybGQifQ==",
    "--X0--",
    CRLF
].joined(separator: CRLF)

let dataAttachementMail = [
    "Content-Type: multipart/mixed; boundary=\"X0\"",
    "",
    "--X0",
    "Content-Type: text/plain; charset=utf-8",
    "Content-Transfer-Encoding: 7bit",
    "Content-Disposition: inline",
    "",
    "Hello",
    "",
    "--X0",
    "CONTENT-TYPE: application/zip",
    "CONTENT-DISPOSITION: inline; filename=\"=?UTF-8?Q?file.zip?=\"",
    "CONTENT-TRANSFER-ENCODING: BASE64",
    "eyJrZXkiOiAiaGVsbG8gd29ybGQifQ==",
    "--X0--",
    CRLF
    ].joined(separator: CRLF)
