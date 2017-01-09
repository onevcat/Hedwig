import XCTest
@testable import Hedwig

class HedwigTests: XCTestCase {
    
    var hegwig: Hedwig!
    
    func testCanSendPlainMail() {
        
        let e = expectation(description: "wait")

        do {
            let hedwig = try Hedwig(hostName: "127.0.0.1", user: "foo@bar.com", password: "password", port: 2255, secure: .plain)
            
            let a1 = Attachment(filePath: "/Users/onevcat/Documents/notification-flow.png", inline: true, additionalHeaders: ["Content-Id": "<hello>"])
            
            let a = Attachment(htmlContent: "<html>\n<body>\n<h2>An important link to look at!</h2>\nHere's an <a href=\"http://www.codestore.net\"><img src=cid:hello>important link， 和中文</a>\n</body>\n</html>", alternative: true, related: [a1])
            
            let mail = try Mail(text: "Miaogu 中文也 Ok", from: "onev@onevcat.com", to: "onevcat@gmail.com", subject: "Test1", attachments: [a])
            hedwig.send([mail], completion: { err in
                e.fulfill()
                if err != nil {
                    XCTFail()
                }
            })
        } catch {
            XCTFail()
        }
        
        waitForExpectations(timeout: 10)
    }


    static var allTests : [(String, (HedwigTests) -> () throws -> Void)] {
        return [
            ("testCanSendPlainMail", testCanSendPlainMail),
        ]
    }
}
