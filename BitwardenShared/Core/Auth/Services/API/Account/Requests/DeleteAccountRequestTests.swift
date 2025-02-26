import Networking
import XCTest

@testable import BitwardenShared

class DeleteAccountRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DeleteAccountRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DeleteAccountRequest()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// Validate that the method is correct.
    func test_method() {
        XCTAssertEqual(subject.method, .delete)
    }

    /// Validate that the path is correct.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts")
    }
}
