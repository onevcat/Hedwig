//
//  AddressParserTests.swift
//  Hedwig
//
//  Created by Wei Wang on 2016/12/31.
//
//

import XCTest
@testable import Hedwig

class AddressParserTests: XCTestCase {
    func testCanParseSingleAddress() {
        let addresses = AddressParser.parse("onev@onevcat.com")
        let expected = [Address(name: "", entry: .mail("onev@onevcat.com"))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseMultipleAddresses() {
        let addresses = AddressParser.parse("onev@onevcat.com, foo@bar.com")
        let expected = [
            Address(name: "", entry: .mail("onev@onevcat.com")),
            Address(name: "", entry: .mail("foo@bar.com"))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseUnquotedName() {
        let addresses = AddressParser.parse("onevcat <onev@onevcat.com>")
        let expected = [
            Address(name: "onevcat", entry: .mail("onev@onevcat.com"))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseQuotedName() {
        let addresses = AddressParser.parse("\"wei wang\" <onev@onevcat.com>")
        let expected = [
            Address(name: "wei wang", entry: .mail("onev@onevcat.com"))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseQuotedSemicolonName() {
        let addresses = AddressParser.parse("\"wei; wang\" <onev@onevcat.com>")
        let expected = [
            Address(name: "wei; wang", entry: .mail("onev@onevcat.com"))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseSingleQuote() {
        let addresses = AddressParser.parse("wei wang <'onev@onevcat.com'>")
        let expected = [Address(name: "wei wang", entry: .mail("onev@onevcat.com"))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseDoubleQuote() {
        let addresses = AddressParser.parse("wei wang <\"onev@onevcat.com\">")
        let expected = [Address(name: "wei wang", entry: .mail("onev@onevcat.com"))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanPaeseQuoteBoth() {
        let addresses = AddressParser.parse("\"onev@onevcat.com\" <\"onev@onevcat.com\">")
        let expected = [Address(name: "", entry: .mail("onev@onevcat.com"))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanPaeseQuoteInline() {
        let addresses = AddressParser.parse("\"onev@onevcat.com\" <onev@onev\"cat.com\">")
        let expected = [Address(name: "onev@onevcat.com", entry: .mail("onev@onev\"cat.com\""))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseUnquotedNameAddress() {
        let addresses = AddressParser.parse("onevcat onev@onevcat.com")
        let expected = [
            Address(name: "onevcat", entry: .mail("onev@onevcat.com"))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseEmptyGroup() {
        let addresses = AddressParser.parse("EmptyGroup:;")
        let expected = [
            Address(name: "EmptyGroup", entry: .group([]))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseGroup() {
        let addresses = AddressParser.parse("MyGroup:onev@onevcat.com, foo@bar.com;")
        let expected = [
            Address(name: "MyGroup", entry: .group([
                Address(name: "", entry: .mail("onev@onevcat.com")),
                Address(name: "", entry: .mail("foo@bar.com")),
            ]))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanRecognizeSemicolon() {
        let addresses = AddressParser.parse("onev@onevcat.com; foo@bar.com")
        let expected = [
            Address(name: "", entry: .mail("onev@onevcat.com")),
            Address(name: "", entry: .mail("foo@bar.com"))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseMixedSingleAndGroup() {
        let addresses = AddressParser.parse("Wei Wang <onev@onevcat.com>, \"My Group\": onev@onevcat.com, foo@bar.com;,, EmptyGroup:;")
        let expected = [
            Address(name: "Wei Wang", entry: .mail("onev@onevcat.com")),
            Address(name: "My Group", entry: .group([
                Address(name: "", entry: .mail("onev@onevcat.com")),
                Address(name: "", entry: .mail("foo@bar.com")),
            ])),
            Address(name: "EmptyGroup", entry: .group([]))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseSemicolonInMixed() {
        let addresses = AddressParser.parse("Wei Wang <onev@onevcat.com>; \"My Group\": onev@onevcat.com, foo@bar.com;,, EmptyGroup:; foo@bar.com")
        let expected = [
            Address(name: "Wei Wang", entry: .mail("onev@onevcat.com")),
            Address(name: "My Group", entry: .group([
                Address(name: "", entry: .mail("onev@onevcat.com")),
                Address(name: "", entry: .mail("foo@bar.com")),
                ])),
            Address(name: "EmptyGroup", entry: .group([])),
            Address(name: "", entry: .mail("foo@bar.com"))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseNameFromComment() {
        let addresses = AddressParser.parse("onev@onevcat.com (onevcat)")
        let expected = [Address(name: "onevcat", entry: .mail("onev@onevcat.com"))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanSkipUnnecessaryComment() {
        let addresses = AddressParser.parse("onev@onevcat.com (wei wang) onevcat")
        let expected = [Address(name: "onevcat", entry: .mail("onev@onevcat.com"))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseMissingAddress() {
        let addresses = AddressParser.parse("onevcat")
        let expected = [Address(name: "onevcat", entry: .mail(""))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseNameApostrophe() {
        let addresses = AddressParser.parse("OneV'sDen")
        let expected = [Address(name: "OneV'sDen", entry: .mail(""))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanUnescapedColon() {
        let addresses = AddressParser.parse("FirstName Surname-WithADash :: Company <firstname@company.com>")
        let expected = [
            Address(name: "FirstName Surname-WithADash", entry: .group([
                Address(name: "", entry: .group([
                    Address(name: "Company", entry: .mail("firstname@company.com"))
                ]))
            ]))
        ]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseInvalidAddress() {
        let addresses = AddressParser.parse("onev@onevcat.com@onevdog.com")
        let expected = [Address(name: "", entry: .mail("onev@onevcat.com@onevdog.com"))]
        XCTAssertEqual(addresses, expected)
    }
    
    func testCanParseInvalidQuote() {
        let addresses = AddressParser.parse("wei wa>ng < onevcat <onev@onevcat.com>")
        let expected = [Address(name: "wei wa>ng", entry: .mail("onev@onevcat.com"))]
        XCTAssertEqual(addresses, expected)
    }

    
    static var allTests : [(String, (AddressParserTests) -> () throws -> Void)] {
        return [
            ("testCanParseSingleAddress", testCanParseSingleAddress),
            ("testCanParseMultipleAddresses", testCanParseMultipleAddresses),
            ("testCanParseUnquotedName", testCanParseUnquotedName),
            ("testCanParseQuotedName", testCanParseQuotedName),
            ("testCanParseQuotedSemicolonName", testCanParseQuotedSemicolonName),
            ("testCanParseSingleQuote", testCanParseSingleQuote),
            ("testCanParseDoubleQuote", testCanParseDoubleQuote),
            ("testCanPaeseQuoteBoth", testCanPaeseQuoteBoth),
            ("testCanPaeseQuoteInline", testCanPaeseQuoteInline),
            ("testCanParseUnquotedNameAddress", testCanParseUnquotedNameAddress),
            ("testCanParseEmptyGroup", testCanParseEmptyGroup),
            ("testCanParseGroup", testCanParseGroup),
            ("testCanRecognizeSemicolon", testCanRecognizeSemicolon),
            ("testCanParseMixedSingleAndGroup", testCanParseMixedSingleAndGroup),
            ("testCanParseSemicolonInMixed", testCanParseSemicolonInMixed),
            ("testCanParseNameFromComment", testCanParseNameFromComment),
            ("testCanSkipUnnecessaryComment", testCanSkipUnnecessaryComment),
            ("testCanParseMissingAddress", testCanParseMissingAddress),
            ("testCanParseNameApostrophe", testCanParseNameApostrophe),
            ("testCanUnescapedColon", testCanUnescapedColon),
            ("testCanParseInvalidAddress", testCanParseInvalidAddress),
            ("testCanParseInvalidQuote", testCanParseInvalidQuote)
        ]
    }
}
