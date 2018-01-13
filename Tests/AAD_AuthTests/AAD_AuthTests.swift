import XCTest
@testable import AAD_Auth

class AAD_AuthTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AAD_Auth().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
