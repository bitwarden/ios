import XCTest

@testable import BitwardenShared

class OptionalTests: BitwardenTestCase {
    // MARK: Tests

    /// `isEmptyOrNil` returns `true` if the wrapped collection is empty.
    func test_isEmptyOrNil_empty() {
        let subject: [String]? = []
        XCTAssertTrue(subject.isEmptyOrNil)
    }

    /// `isEmptyOrNil` returns `true` if the value is `nil`.
    func test_isEmptyOrNil_nil() {
        let subject: [String]? = nil
        XCTAssertTrue(subject.isEmptyOrNil)
    }

    /// `isEmptyOrNil` returns `false` if the wrapped collection is not empty.
    func test_isEmptyOrNil_notEmpty() {
        let subject: [String]? = ["a", "b", "c"]
        XCTAssertFalse(subject.isEmptyOrNil)
    }
}
