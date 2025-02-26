import Networking
import XCTest

@testable import BitwardenShared

class AccountRevisionDateRequestTests: BitwardenTestCase {
    // MARK: Tests

    /// Validate that the method is correct.
    func test_method() {
        XCTAssertEqual(AccountRevisionDateRequest().method, .get)
    }

    /// Validate that the path is correct.
    func test_path() {
        XCTAssertEqual(AccountRevisionDateRequest().path, "/accounts/revision-date")
    }
}
