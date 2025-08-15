import XCTest

@testable import BitwardenShared

class CollectionTypeTests: BitwardenTestCase {
    /// `defaultValue` returns the default value for the type if an invalid or missing value is
    /// received when decoding the type.
    func test_defaultValue() {
        XCTAssertEqual(CollectionType.defaultValue, .sharedCollection)
    }
}
