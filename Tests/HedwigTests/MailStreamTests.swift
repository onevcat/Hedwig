//
//  MailStreamTests.swift
//  Hedwig
//
//  Created by Wei Wang on 2017/1/9.
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

class MailStreamTests: XCTestCase {

    func testCanStreamPlainMail() {
        let mail = try! Mail(text: "Across the great wall we can reach every corner in the world.", from: "onev@onevcat.com", to: "foo@bar.com")
        let streamed = mail.streamedContent()
        let expected = mail.concatHeader(with: plainMail)
        XCTAssertEqual(streamed, expected)
    }
    
    func testCanStreamMailWithHTMLAttachment() {
        let html = Attachment(htmlContent: "<html></html>", alternative: false)
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
    
    func testCanStreamAlternativeHTMLAttachment() {
        let html = Attachment(htmlContent: "<html></html>")
        let mail = try! Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title", attachments: [html])
        
        let streamed = mail.streamedContent()
        let expected = mail.concatHeader(with: alternativeHtmlAttachmentMail)
        XCTAssertEqual(streamed.boundaryUnified, expected)
    }
    
    func testCanStreamMultipleAttachments() {
        let htmlAttachment = Attachment(htmlContent: "<html></html>")
        
        let data = "{\"key\": \"hello world\"}".data(using: .utf8)!
        let dataAttachment = Attachment(data: data, mime: "application/json", name: "file.json")
        
        let mail = try! Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title", attachments: [htmlAttachment, dataAttachment])
        
        let streamed = mail.streamedContent()
        let expected = mail.concatHeader(with: multipleAttachementsMail)
        XCTAssertEqual(streamed.boundaryUnified, expected)
    }
    
    func testCanStreamRelatedAttachment() {
        let data = Data(base64Encoded: imageInBase64)!
        let dataAttachemet = Attachment(data: data, mime: "image/jpg", name: "hedwig.jpg", inline: true, additionalHeaders: ["Content-ID": "hedwig-image"])
        let html = Attachment(htmlContent: "<html><body><h2>Hello Hedwig</h>A photo <img src=\"cid:hedwig-image\"/>. Send the mail to <a href=\"https://onevcat.com\">me</a> please.</body></html>", related: [dataAttachemet])
        
        let mail = try! Mail(text: "Hello", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title", attachments: [html])
        let streamed = mail.streamedContent()
        let expected = mail.concatHeader(with: relatedAttachementsMail)
        XCTAssertEqual(streamed.boundaryUnified, expected)
    }
    
    func testCanStreamNonAscii() {
        let mail = try! Mail(text: "你好，中国。", from: "onev@onevcat.com", to: "foo@bar.com")
        let streamed = mail.streamedContent()
        let expected = mail.concatHeader(with: nonAsciiMail)
        XCTAssertEqual(streamed, expected)
    }
    
    static var allTests : [(String, (MailStreamTests) -> () throws -> Void)] {
        return [
            ("testCanStreamPlainMail", testCanStreamPlainMail),
            ("testCanStreamMailWithHTMLAttachment", testCanStreamMailWithHTMLAttachment),
            ("testCanStreamMailWithFileAttachment", testCanStreamMailWithFileAttachment),
            ("testCanStreamMailWithDataAttachment", testCanStreamMailWithDataAttachment),
            ("testCanStreamAlternativeHTMLAttachment", testCanStreamAlternativeHTMLAttachment),
            ("testCanStreamMultipleAttachments", testCanStreamMultipleAttachments),
            ("testCanStreamRelatedAttachment", testCanStreamRelatedAttachment),
            ("testCanStreamNonAscii", testCanStreamNonAscii)
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
        print(replaces)
        var s = self
        for (replace, boundary) in zip(replaces, boundaries) {
            
            // Linux replacingOccurrences will fail when there is \r in string.
            // Workaround to replace strings without CRLF.
            let r = s.components(separatedBy: CRLF)
            s = r.map {
                $0.replacingOccurrences(of: boundary, with: replace)
            }.joined(separator: CRLF)
        }
        return s
    }
    
    var boundaries: [String] {
        var result = [String]()
        let pattern = try! Regex(pattern: "boundary=\"((.+?))\"", options: [])
        let matches = pattern.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
        
        for match in matches {
            #if os(Linux)
            let range = match.range(at: 1)
            #else
            let range = match.rangeAt(1)
            #endif

            let boundary = NSString(string: self).substring(with: range)
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
    "Across the great wall we can reach every corner in the world.",
    CRLF
].joined(separator: CRLF)

let nonAsciiMail = [
    "Content-Type: text/plain; charset=utf-8",
    "Content-Transfer-Encoding: 7bit",
    "Content-Disposition: inline",
    "",
    "你好，中国。",
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
    [
    "CONTENT-TYPE": "text/html; charset=utf-8",
    "CONTENT-DISPOSITION": "inline",
    "CONTENT-TRANSFER-ENCODING": "BASE64"
    ].toString(),
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
    [
    "CONTENT-TYPE": "application/json",
    "CONTENT-DISPOSITION": "attachment; filename=\"=?UTF-8?Q?attachment.json?=\"",
    "CONTENT-TRANSFER-ENCODING": "BASE64",
    "HEADER-KEY": "header-value",
    
    ].toString(),
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
    [
    "CONTENT-TYPE": "application/zip",
    "CONTENT-DISPOSITION": "inline; filename=\"=?UTF-8?Q?file.zip?=\"",
    "CONTENT-TRANSFER-ENCODING": "BASE64"
    ].toString(),
    "eyJrZXkiOiAiaGVsbG8gd29ybGQifQ==",
    "--X0--",
    CRLF
    ].joined(separator: CRLF)

let alternativeHtmlAttachmentMail = [
    "Content-Type: multipart/mixed; boundary=\"X0\"",
    "",
    "--X0",
    "Content-Type: multipart/alternative; boundary=\"X1\"",
    "",
    "--X1",
    "Content-Type: text/plain; charset=utf-8",
    "Content-Transfer-Encoding: 7bit",
    "Content-Disposition: inline",
    "",
    "Hello",
    "",
    "--X1",
    [
    "CONTENT-TYPE": "text/html; charset=utf-8",
    "CONTENT-DISPOSITION": "inline",
    "CONTENT-TRANSFER-ENCODING": "BASE64"
    ].toString(),
    "PGh0bWw+PC9odG1sPg==",
    "--X1--",
    "",
    "",
    "--X0--",
    CRLF
    ].joined(separator: CRLF)

let multipleAttachementsMail = [
    "Content-Type: multipart/mixed; boundary=\"X0\"",
    "",
    "--X0",
    "Content-Type: multipart/alternative; boundary=\"X1\"",
    "",
    "--X1",
    "Content-Type: text/plain; charset=utf-8",
    "Content-Transfer-Encoding: 7bit",
    "Content-Disposition: inline",
    "",
    "Hello",
    "",
    "--X1",
    [
    "CONTENT-TYPE": "text/html; charset=utf-8",
    "CONTENT-DISPOSITION": "inline",
    "CONTENT-TRANSFER-ENCODING": "BASE64"
    ].toString(),
    "PGh0bWw+PC9odG1sPg==",
    "--X1--",
    "",
    "--X0",
    [
    "CONTENT-TYPE": "application/json",
    "CONTENT-DISPOSITION": "attachment; filename=\"=?UTF-8?Q?file.json?=\"",
    "CONTENT-TRANSFER-ENCODING": "BASE64"
    ].toString(),
    "eyJrZXkiOiAiaGVsbG8gd29ybGQifQ==",
    "--X0--",
    CRLF
].joined(separator: CRLF)

let relatedAttachementsMail = [
    "Content-Type: multipart/mixed; boundary=\"X0\"",
    "",
    "--X0",
    "Content-Type: multipart/alternative; boundary=\"X1\"",
    "",
    "--X1",
    "Content-Type: text/plain; charset=utf-8",
    "Content-Transfer-Encoding: 7bit",
    "Content-Disposition: inline",
    "",
    "Hello",
    "",
    "--X1",
    "Content-Type: multipart/related; boundary=\"X2\"",
    "",
    "--X2",
    [
    "CONTENT-TYPE": "text/html; charset=utf-8",
    "CONTENT-DISPOSITION": "inline",
    "CONTENT-TRANSFER-ENCODING": "BASE64"
    ].toString(),
    "PGh0bWw+PGJvZHk+PGgyPkhlbGxvIEhlZHdpZzwvaD5BIHBob3RvIDxpbWcgc3JjPSJjaWQ6aGVkd2lnLWltYWdlIi8+LiBTZW5kIHRoZSBtYWlsIHRvIDxhIGhyZWY9Imh0dHBzOi8vb25ldmNhdC5jb20iPm1lPC9hPiBwbGVhc2UuPC9ib2R5PjwvaHRtbD4=",
    "",
    "--X2",
    [
    "CONTENT-TYPE": "image/jpg",
    "CONTENT-DISPOSITION": "inline; filename=\"=?UTF-8?Q?hedwig.jpg?=\"",
    "CONTENT-TRANSFER-ENCODING": "BASE64",
    "CONTENT-ID": "hedwig-image"
    ].toString(),
    imageInBase64,
    "--X2--",
    "",
    "",
    "--X1--",
    "",
    "",
    "--X0--",
    CRLF
].joined(separator: CRLF)

extension Dictionary {
    func toString() -> String {
        var r = [String]()
        for (key, value) in self {
            r.append("\(key): \(value)")
        }
        return r.joined(separator: CRLF)
    }
}

let imageInBase64 = "/9j/4AAQSkZJRgABAQAASABIAAD/4QCoRXhpZgAATU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgExAAIAAAAcAAAAWodpAAQAAAABAAAAdgAAAAAAAABIAAAAAQAAAEgAAAABQWRvYmUgUGhvdG9zaG9wIENTNSBXaW5kb3dzAAADoAEAAwAAAAEAAQAAoAIABAAAAAEAAABkoAMABAAAAAEAAAB4AAAAAP/hCvpodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6RUNFMDcwQjU5NkY1MTFFMDg3RTZFQ0EzNEMwN0RDRDQiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6RUNFMDcwQjY5NkY1MTFFMDg3RTZFQ0EzNEMwN0RDRDQiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBXaW5kb3dzIj4gPHhtcE1NOkRlcml2ZWRGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6RUNFMDcwQjM5NkY1MTFFMDg3RTZFQ0EzNEMwN0RDRDQiIHN0UmVmOmRvY3VtZW50SUQ9InhtcC5kaWQ6RUNFMDcwQjQ5NkY1MTFFMDg3RTZFQ0EzNEMwN0RDRDQiLz4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgPD94cGFja2V0IGVuZD0idyI/PgD/7QA4UGhvdG9zaG9wIDMuMAA4QklNBAQAAAAAAAA4QklNBCUAAAAAABDUHYzZjwCyBOmACZjs+EJ+/8AAEQgAeABkAwERAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMABgQEBAUEBgUFBgkGBQYJCwgGBggLDAoKCwoKDBAMDAwMDAwQDA4PEA8ODBMTFBQTExwbGxscHx8fHx8fHx8fH//bAEMBBwcHDQwNGBAQGBoVERUa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"
