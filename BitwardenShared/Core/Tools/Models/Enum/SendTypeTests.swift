import XCTest

@testable import BitwardenShared

// MARK: - SendTypeTests

class SendTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `requiresPremium` returns the correct value for each type.
    func test_requiresPremium() {
        XCTAssertTrue(SendType.file.requiresPremium)
        XCTAssertFalse(SendType.text.requiresPremium)
    }
}
