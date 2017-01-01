import XCTest
@testable import Hedwig

class HedwigTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        XCTAssertEqual(Hedwig().text, "Hello, World!")
    }


    static var allTests : [(String, (HedwigTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
