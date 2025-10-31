import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - VaultListDirectorStrategyFactoryTests

class VaultListDirectorStrategyFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var subject: VaultListDirectorStrategyFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultVaultListDirectorStrategyFactory(
            cipherService: MockCipherService(),
            collectionService: MockCollectionService(),
            fido2UserInterfaceHelper: MockFido2UserInterfaceHelper(),
            folderService: MockFolderService(),
            vaultListBuilderFactory: MockVaultListSectionsBuilderFactory(),
            vaultListDataPreparator: MockVaultListDataPreparator(),
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `make(filter:)` returns `CombinedMultipleAutofillVaultListDirectorStrategy` when
    /// filtering by mode `.combinedMultipleSections`.
    func test_make_returnsCombinedMultipleAutofillVaultListDirectorStrategy() {
        let stragegy = subject.make(filter: VaultListFilter(mode: .combinedMultipleSections))
        XCTAssertTrue(stragegy is CombinedMultipleAutofillVaultListDirectorStrategy)
    }

    /// `make(filter:)` returns `CombinedSingleAutofillVaultListDirectorStrategy` when
    /// filtering by mode `.combinedSingleSection`.
    func test_make_returnsCombinedSingleAutofillVaultListDirectorStrategy() {
        let stragegy = subject.make(filter: VaultListFilter(mode: .combinedSingleSection))
        XCTAssertTrue(stragegy is CombinedSingleAutofillVaultListDirectorStrategy)
    }

    /// `make(filter:)` returns `MainVaultListDirectorStrategy` when not filtering by group.
    func test_make_returnsMainVaultStrategy() {
        let stragegy = subject.make(filter: VaultListFilter(group: nil))
        XCTAssertTrue(stragegy is MainVaultListDirectorStrategy)
    }

    /// `make(filter:)` returns `MainVaultListGroupDirectorStrategy` when  filtering by group.
    func test_make_returnsMainVaultGroupStrategy() {
        let stragegy = subject.make(filter: VaultListFilter(group: .login))
        XCTAssertTrue(stragegy is MainVaultListGroupDirectorStrategy)
    }

    /// `make(filter:)` returns `PasswordsAutofillVaultListDirectorStrategy` when  filtering by passwords
    /// autofill mode.
    func test_make_returnsPasswordsAutofillVaultListDirectorStrategy() {
        let stragegy = subject.make(filter: VaultListFilter(mode: .passwords))
        XCTAssertTrue(stragegy is PasswordsAutofillVaultListDirectorStrategy)
    }
}
