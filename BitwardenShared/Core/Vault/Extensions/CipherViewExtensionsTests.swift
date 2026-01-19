import BitwardenSdk
import BitwardenSharedMocks
import XCTest

@testable import BitwardenShared

// MARK: - CipherViewExtensionsTests

class CipherViewExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `isHidden` return `true` when the cipher is hidden, i.e. archived or deleted; `false` otherwise.
    func test_isHidden() {
        XCTAssertTrue(CipherView.fixture(archivedDate: .now).isHidden)
        XCTAssertTrue(CipherView.fixture(deletedDate: .now).isHidden)
        XCTAssertTrue(CipherView.fixture(archivedDate: .now, deletedDate: .now).isHidden)
        XCTAssertFalse(CipherView.fixture(archivedDate: nil, deletedDate: nil).isHidden)
    }
}
