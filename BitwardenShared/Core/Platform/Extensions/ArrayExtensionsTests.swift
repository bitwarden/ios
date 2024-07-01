import XCTest

@testable import BitwardenShared

class ArrayExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `subscript(safeIndex:)` returns `nil` when outside of bounds on an array with elements.
    func test_subscriptSafeIndex_nil() {
        let array = [1, 2, 3]

        XCTAssertNil(array[safeIndex: -1])
        XCTAssertNil(array[safeIndex: 3])
    }

    /// `subscript(safeIndex:)` returns `nil` when trying to look in an empty array.
    func test_subscriptSafeIndex_nilEmpty() {
        let array: [Int] = []

        XCTAssertNil(array[safeIndex: 0])
    }

    /// `subscript(safeIndex:)` returns the correct element when inside the bounds.
    func test_subscriptSafeIndex_element() {
        let array = [1, 2, 3]
        XCTAssertEqual(1, array[safeIndex: 0])
        XCTAssertEqual(2, array[safeIndex: 1])
        XCTAssertEqual(3, array[safeIndex: 2])
    }
}
