import XCTest
@testable import HedwigTests

XCTMain([
     testCase(HedwigTests.allTests),
     testCase(SMTPTests.allTests)
])
