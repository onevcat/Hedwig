import XCTest
@testable import HedwigTests

XCTMain([
     testCase(HedwigTests.allTests),
     testCase(SMTPTests.allTests),
     testCase(CryptoEncoderTests.allTests),
     testCase(MailTests.allTests),
     testCase(MailStreamTests.allTests)
])
