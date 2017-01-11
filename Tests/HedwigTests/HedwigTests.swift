import XCTest
@testable import Hedwig

class HedwigTests: XCTestCase {
    
    var hedwig: Hedwig!
    
    override func setUp() {
        hedwig = Hedwig(hostName: "onevcat.com", user: "foo@bar.com", password: "password", port: 2255, secure: .plain)
    }
    
    func testCanSendMail() {
        
        let e = expectation(description: "wait")

        let plainMail = try! Mail(text: "Hello World", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title")
        hedwig.send(plainMail) { error in
            if error != nil { XCTFail("Should no error happens, but \(error)") }
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func testCanSendMultipleMails() {
        let e = expectation(description: "wait")
        let mail1 = try! Mail(text: "Hello World", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title")
        let mail2 = try! Mail(text: "Hello World Again", from: "onev@onevcat.com", to: "foo@bar.com", subject: "Title")
        
        var count = 0
        hedwig.send([mail1, mail2], progress: { _ in
            count += 1
        }) { error in
            if error != nil { XCTFail("Should no error happens, but \(error)") }
            XCTAssertEqual(count, 2)
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    static var allTests : [(String, (HedwigTests) -> () throws -> Void)] {
        return [
            ("testCanSendMail", testCanSendMail),
            ("testCanSendMultipleMails", testCanSendMultipleMails)
        ]
    }
}
