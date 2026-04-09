import BitwardenSdk
import BitwardenSharedMocks
import XCTest

@testable import BitwardenShared

// MARK: - CipherViewExtensionsTests

class CipherViewExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `canBeArchived` returns `true` when the cipher can be archived (not already archived and not deleted).
    func test_canBeArchived() {
        XCTAssertTrue(CipherView.fixture(archivedDate: nil, deletedDate: nil).canBeArchived)
        XCTAssertFalse(CipherView.fixture(archivedDate: .now, deletedDate: nil).canBeArchived)
        XCTAssertFalse(CipherView.fixture(archivedDate: nil, deletedDate: .now).canBeArchived)
        XCTAssertFalse(CipherView.fixture(archivedDate: .now, deletedDate: .now).canBeArchived)
    }

    /// `canBeUnarchived` returns `true` when the cipher can be unarchived (archived but not deleted).
    func test_canBeUnarchived() {
        XCTAssertTrue(CipherView.fixture(archivedDate: .now, deletedDate: nil).canBeUnarchived)
        XCTAssertFalse(CipherView.fixture(archivedDate: nil, deletedDate: nil).canBeUnarchived)
        XCTAssertFalse(CipherView.fixture(archivedDate: nil, deletedDate: .now).canBeUnarchived)
        XCTAssertFalse(CipherView.fixture(archivedDate: .now, deletedDate: .now).canBeUnarchived)
    }

    /// `isHidden` return `true` when the cipher is hidden, i.e. archived or deleted; `false` otherwise.
    func test_isHidden() {
        XCTAssertTrue(CipherView.fixture(archivedDate: .now).isHidden)
        XCTAssertTrue(CipherView.fixture(deletedDate: .now).isHidden)
        XCTAssertTrue(CipherView.fixture(archivedDate: .now, deletedDate: .now).isHidden)
        XCTAssertFalse(CipherView.fixture(archivedDate: nil, deletedDate: nil).isHidden)
    }
}
