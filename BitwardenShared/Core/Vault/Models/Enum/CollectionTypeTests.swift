import XCTest

@testable import BitwardenShared

class CollectionTypeTests: BitwardenTestCase {
    /// `defaultValue` returns the default value for the type.
    func test_defaultValue() {
        XCTAssertEqual(CollectionType.defaultValue, .sharedCollection)
    }
}
