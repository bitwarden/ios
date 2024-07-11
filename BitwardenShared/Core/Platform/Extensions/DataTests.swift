import XCTest

@testable import BitwardenShared

class DataTests: BitwardenTestCase {
    // MARK: Tests

    /// `asHexString()` converts the Data object into a hex formatted string.
    func test_asHexString() {
        let subject = Data(repeating: 1, count: 32)
        XCTAssertEqual(
            subject.asHexString(),
            "0101010101010101010101010101010101010101010101010101010101010101"
        )
    }
}
