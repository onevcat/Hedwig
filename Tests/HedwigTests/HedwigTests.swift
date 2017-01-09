import XCTest
@testable import Hedwig

class HedwigTests: XCTestCase {
    
    var hedwig: Hedwig!
    
    override func setUp() {
        hedwig = Hedwig(hostName: "127.0.0.1", user: "foo@bar.com", password: "password", port: 2255, secure: .plain)
    }
    
    func testCanSendPlainMail() {
        
        let e = expectation(description: "wait")

        let plainMail = try! Mail(text: "Hello World", from: "onev@onevcat.com", to: "onevcat@gmail.com", subject: "Title")
        hedwig.send(plainMail) { error in
            if error != nil { XCTFail("Should no error happens, but \(error)") }
            e.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    


    static var allTests : [(String, (HedwigTests) -> () throws -> Void)] {
        return [
            ("testCanSendPlainMail", testCanSendPlainMail),
        ]
    }
}
