import XCTest

@testable import AuthenticatorShared

class CollectionTests: AuthenticatorTestCase {
    /// `nilIfEmpty` returns the array if it's not empty or `nil` if it's empty.
    func test_nilIfEmpty_array() {
        XCTAssertEqual([1].nilIfEmpty, [1])
        XCTAssertEqual([1, 2, 3].nilIfEmpty, [1, 2, 3])

        XCTAssertNil([Int]().nilIfEmpty)
    }

    /// `nilIfEmpty` returns the string if it's not empty or `nil` if it's empty.
    func test_nilIfEmpty_string() {
        XCTAssertEqual("abc".nilIfEmpty, "abc")
        XCTAssertEqual("asdf1234".nilIfEmpty, "asdf1234")

        XCTAssertNil("".nilIfEmpty)
    }
}
