import XCTest
@testable import Hedwig

class HedwigTests: XCTestCase {
    func testExample() {
        
        let e = expectation(description: "wait")

        let hedwig = Hedwig(hostName: "127.0.0.1", user: "foo@bar.com", password: "password", secure: .plain, completion: { err in
            e.fulfill()
            if err != nil {
                XCTFail()
            }
        })
        
        if let hedwig = hedwig {
            do {
                let mail = try Mail(text: "Hello", from: "onevcat@gmail.com", to: "onev@onevcat.com", subject: "Hello world.")
                hedwig.send([mail])
            } catch {
                
            }
        }
        
        waitForExpectations(timeout: 10)
    }


    static var allTests : [(String, (HedwigTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
