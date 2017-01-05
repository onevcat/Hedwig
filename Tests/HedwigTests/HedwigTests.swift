import XCTest
@testable import Hedwig

class HedwigTests: XCTestCase {
    func testExample() {
        
        let e = expectation(description: "wait")

        do {
            let hedwig = try Hedwig(hostName: "127.0.0.1", user: "foo@bar.com", password: "password", secure: .plain, completion: { err in
                e.fulfill()
                if err != nil {
                    XCTFail()
                }
            })
            
            let a = Attachment(htmlContent: "<html>\n<body>\n<h2>An important link to look at!</h2>\nHere's an <a href=\"http://www.codestore.net\">important link</a>\n</body>\n</html>", alternative: true)
            let mail = try Mail(text: "Hello", from: "onev@onevcat.com", to: "onevcat@gmail.com", subject: "Mail contains att", attachments: [a])
            hedwig.send([mail])
        } catch {
            XCTFail()
        }
        
        waitForExpectations(timeout: 10)
    }


    static var allTests : [(String, (HedwigTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
