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
            folderService: MockFolderService(),
            vaultListBuilderFactory: MockVaultListSectionsBuilderFactory(),
            vaultListDataPreparator: MockVaultListDataPreparator()
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

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
