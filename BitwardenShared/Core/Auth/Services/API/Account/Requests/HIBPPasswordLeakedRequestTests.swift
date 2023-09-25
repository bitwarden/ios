import XCTest

@testable import BitwardenShared

class HIBPPasswordLeakedRequestTests: BitwardenTestCase {
    /// Validate that the method is correct.
    func test_method() {
        let subject = HIBPPasswordLeakedRequest(passwordHashPrefix: "12345")
        XCTAssertEqual(subject.method, .get)
    }

    /// Validate that the path is correct.
    func test_path() {
        let subject = HIBPPasswordLeakedRequest(passwordHashPrefix: "12345")
        XCTAssertEqual(subject.path, "/range/12345")
    }
}
