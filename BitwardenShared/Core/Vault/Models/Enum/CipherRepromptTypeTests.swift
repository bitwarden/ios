import XCTest

@testable import BitwardenShared

class CipherRepromptTypeTests: BitwardenTestCase {
    /// `defaultValue` returns the default value for the type if an invalid or missing value is
    /// received when decoding the type.
    func test_defaultValue() {
        XCTAssertEqual(CipherRepromptType.defaultValue, .none)
    }
}
