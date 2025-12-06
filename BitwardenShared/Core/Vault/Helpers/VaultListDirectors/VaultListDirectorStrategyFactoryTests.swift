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
        let strategy = subject.make(filter: VaultListFilter(mode: .combinedMultipleSections))
        XCTAssertTrue(strategy is CombinedMultipleAutofillVaultListDirectorStrategy)
    }

    /// `make(filter:)` returns `CombinedSingleAutofillVaultListDirectorStrategy` when
    /// filtering by mode `.combinedSingleSection`.
    func test_make_returnsCombinedSingleAutofillVaultListDirectorStrategy() {
        let strategy = subject.make(filter: VaultListFilter(mode: .combinedSingleSection))
        XCTAssertTrue(strategy is CombinedSingleAutofillVaultListDirectorStrategy)
    }

    /// `make(filter:)` returns `MainVaultListDirectorStrategy` when not filtering by group.
    func test_make_returnsMainVaultStrategy() {
        let strategy = subject.make(filter: VaultListFilter(group: nil))
        XCTAssertTrue(strategy is MainVaultListDirectorStrategy)
    }

    /// `make(filter:)` returns `MainVaultListGroupDirectorStrategy` when  filtering by group.
    func test_make_returnsMainVaultGroupStrategy() {
        let strategy = subject.make(filter: VaultListFilter(group: .login))
        XCTAssertTrue(strategy is MainVaultListGroupDirectorStrategy)
    }

    /// `make(filter:)` returns `PasswordsAutofillVaultListDirectorStrategy` when  filtering by passwords
    /// autofill mode.
    func test_make_returnsPasswordsAutofillVaultListDirectorStrategy() {
        let strategy = subject.make(filter: VaultListFilter(mode: .passwords))
        XCTAssertTrue(strategy is PasswordsAutofillVaultListDirectorStrategy)
    }

    /// `makeSearchStrategy(mode:)` returns `SearchCombinedMultipleAutofillListDirectorStrategy` when
    /// mode is `.combinedMultipleSections`.
    func test_makeSearchStrategy_returnsSearchCombinedMultipleAutofillListDirectorStrategy() {
        let strategy = subject.makeSearchStrategy(mode: .combinedMultipleSections)
        XCTAssertTrue(strategy is SearchCombinedMultipleAutofillListDirectorStrategy)
    }

    /// `makeSearchStrategy(mode:)` returns `SearchVaultListDirectorStrategy` when
    /// mode is not `.combinedMultipleSections`.
    func test_makeSearchStrategy_returnsSearchVaultListDirectorStrategy() {
        let strategy1 = subject.makeSearchStrategy(mode: .all)
        XCTAssertTrue(strategy1 is SearchVaultListDirectorStrategy)

        let strategy2 = subject.makeSearchStrategy(mode: .combinedSingleSection)
        XCTAssertTrue(strategy2 is SearchVaultListDirectorStrategy)

        let strategy3 = subject.makeSearchStrategy(mode: .passwords)
        XCTAssertTrue(strategy3 is SearchVaultListDirectorStrategy)

        let strategy4 = subject.makeSearchStrategy(mode: .totp)
        XCTAssertTrue(strategy4 is SearchVaultListDirectorStrategy)
    }
}
