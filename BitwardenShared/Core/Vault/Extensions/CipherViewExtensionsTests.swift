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

    /// `isHiddenWithArchiveFF` returns `true` when cipher is deleted, regardless of feature flag state.
    func test_isHiddenWithArchiveFF_deleted() {
        let deletedCipher = CipherView.fixture(archivedDate: nil, deletedDate: .now)
        XCTAssertTrue(deletedCipher.isHiddenWithArchiveFF(flag: true))
        XCTAssertTrue(deletedCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `isHiddenWithArchiveFF` returns `true` when cipher is both archived and deleted,
    /// regardless of feature flag state.
    func test_isHiddenWithArchiveFF_archivedAndDeleted() {
        let archivedAndDeletedCipher = CipherView.fixture(archivedDate: .now, deletedDate: .now)
        XCTAssertTrue(archivedAndDeletedCipher.isHiddenWithArchiveFF(flag: true))
        XCTAssertTrue(archivedAndDeletedCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `isHiddenWithArchiveFF` returns `true` when cipher is archived and feature flag is enabled.
    func test_isHiddenWithArchiveFF_archivedWithFlagEnabled() {
        let archivedCipher = CipherView.fixture(archivedDate: .now, deletedDate: nil)
        XCTAssertTrue(archivedCipher.isHiddenWithArchiveFF(flag: true))
    }

    /// `isHiddenWithArchiveFF` returns `false` when cipher is archived but feature flag is disabled.
    func test_isHiddenWithArchiveFF_archivedWithFlagDisabled() {
        let archivedCipher = CipherView.fixture(archivedDate: .now, deletedDate: nil)
        XCTAssertFalse(archivedCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `isHiddenWithArchiveFF` returns `false` when cipher is neither archived nor deleted,
    /// regardless of feature flag state.
    func test_isHiddenWithArchiveFF_notHidden() {
        let normalCipher = CipherView.fixture(archivedDate: nil, deletedDate: nil)
        XCTAssertFalse(normalCipher.isHiddenWithArchiveFF(flag: true))
        XCTAssertFalse(normalCipher.isHiddenWithArchiveFF(flag: false))
    }
}
