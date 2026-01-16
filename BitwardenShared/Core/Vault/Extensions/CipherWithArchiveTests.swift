import XCTest

@testable import BitwardenShared

// MARK: - CipherWithArchiveTests

class CipherWithArchiveTests: BitwardenTestCase {
    // MARK: Tests

    /// `isHiddenWithArchiveFF` returns `true` when cipher is deleted, regardless of feature flag state.
    func test_isHiddenWithArchiveFF_deleted() {
        let deletedCipher = CipherWithArchiveStub(archivedDate: nil, deletedDate: .now)
        XCTAssertTrue(deletedCipher.isHiddenWithArchiveFF(flag: true))
        XCTAssertTrue(deletedCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `isHiddenWithArchiveFF` returns `true` when cipher is both archived and deleted,
    /// regardless of feature flag state.
    func test_isHiddenWithArchiveFF_archivedAndDeleted() {
        let archivedAndDeletedCipher = CipherWithArchiveStub(archivedDate: .now, deletedDate: .now)
        XCTAssertTrue(archivedAndDeletedCipher.isHiddenWithArchiveFF(flag: true))
        XCTAssertTrue(archivedAndDeletedCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `isHiddenWithArchiveFF` returns `true` when cipher is archived and feature flag is enabled.
    func test_isHiddenWithArchiveFF_archivedWithFlagEnabled() {
        let archivedCipher = CipherWithArchiveStub(archivedDate: .now, deletedDate: nil)
        XCTAssertTrue(archivedCipher.isHiddenWithArchiveFF(flag: true))
    }

    /// `isHiddenWithArchiveFF` returns `false` when cipher is archived but feature flag is disabled.
    func test_isHiddenWithArchiveFF_archivedWithFlagDisabled() {
        let archivedCipher = CipherWithArchiveStub(archivedDate: .now, deletedDate: nil)
        XCTAssertFalse(archivedCipher.isHiddenWithArchiveFF(flag: false))
    }

    /// `isHiddenWithArchiveFF` returns `false` when cipher is neither archived nor deleted,
    /// regardless of feature flag state.
    func test_isHiddenWithArchiveFF_notHidden() {
        let normalCipher = CipherWithArchiveStub(archivedDate: nil, deletedDate: nil)
        XCTAssertFalse(normalCipher.isHiddenWithArchiveFF(flag: true))
        XCTAssertFalse(normalCipher.isHiddenWithArchiveFF(flag: false))
    }
}

// MARK: - CipherWithArchiveStub

/// Stub to be use for the `CipherWithArchive` protocol.
struct CipherWithArchiveStub: CipherWithArchive {
    /// The archived date.
    let archivedDate: Date?
    /// The deleted date.
    let deletedDate: Date?
}
