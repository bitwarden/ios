import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - VaultListDataPreparatorTests

class VaultListDataPreparatorTests: BitwardenTestCase {
    // MARK: Properties

    var ciphersClientWrapperService: MockCiphersClientWrapperService!
    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var policyService: MockPolicyService!
    var stateService: MockStateService!
    var subject: VaultListDataPreparator!
    var vaultListPreparedDataBuilder: VaultListPreparedDataBuilderMock!
    var vaultListPreparedDataBuilderFactory: VaultListPreparedDataBuilderFactoryMock!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        ciphersClientWrapperService = MockCiphersClientWrapperService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        policyService = MockPolicyService()
        stateService = MockStateService()

        vaultListPreparedDataBuilder = VaultListPreparedDataBuilderMock()
        vaultListPreparedDataBuilder.setUpFluentReturn()
        vaultListPreparedDataBuilder.buildReturnValue = VaultListPreparedData()

        vaultListPreparedDataBuilderFactory = VaultListPreparedDataBuilderFactoryMock()
        vaultListPreparedDataBuilderFactory.makeReturnValue = vaultListPreparedDataBuilder

        subject = DefaultVaultListDataPreparator(
            ciphersClientWrapperService: ciphersClientWrapperService,
            clientService: clientService,
            errorReporter: errorReporter,
            policyService: policyService,
            stateService: stateService,
            vaultListPreparedDataBuilderFactory: vaultListPreparedDataBuilderFactory
        )
    }

    override func tearDown() {
        super.tearDown()

        ciphersClientWrapperService = nil
        clientService = nil
        errorReporter = nil
        policyService = nil
        stateService = nil
        vaultListPreparedDataBuilder = nil
        vaultListPreparedDataBuilderFactory = nil
        subject = nil
    }

    // MARK: Tests

    /// `prepareData(from:collections:folders:filter:)` returns `nil` when no ciphers passed.
    func test_prepareData_noCiphers() async throws {
        let result = try await subject.prepareData(
            from: [],
            collections: [],
            folders: [],
            filter: VaultListFilter()
        )
        XCTAssertNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns the prepared data without filtering out cipher.
    func test_prepareData_returnsPreparedDataNoFilteringOutCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture()

        let result = try await subject.prepareData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(addTOTPGroup: true)
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCipherDeletedCountCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.incrementTOTPCountCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addFavoriteItemCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addNoFolderItemCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.incrementCipherTypeCountCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertNotNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns the prepared data without filtering out cipher
    /// but it doesn't try to increment TOTP count because the filter doesn't add TOTP group.
    func test_prepareData_returnsPreparedDataNoFilteringOutCipherNoTOTPGroup() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture()

        let result = try await subject.prepareData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(addTOTPGroup: false)
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCipherDeletedCountCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementTOTPCountCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addFavoriteItemCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addNoFolderItemCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.incrementCipherTypeCountCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertNotNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when vault list filter is `.myVault` and the cipher belongs to an organization.
    func test_prepareData_withMyVaultFilterAndBelongingToOrganization() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1"
        )

        let result = try await subject.prepareData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(addTOTPGroup: true, filterType: .myVault)
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCipherDeletedCountCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementTOTPCountCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFavoriteItemCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addNoFolderItemCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCipherTypeCountCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertNotNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when not passing restrict item types policy.
    func test_prepareData_noPassingRestrictItemTypesPolicy() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1"
        )
        policyService.passesRestrictItemTypesPolicyResult = false

        let result = try await subject.prepareData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter()
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCipherDeletedCountCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementTOTPCountCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFavoriteItemCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addNoFolderItemCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCipherTypeCountCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertNotNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when having a deleted date, but incrementing the count of deleted items.
    func test_prepareData_withDeletedDate() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            deletedDate: .now
        )

        let result = try await subject.prepareData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter()
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.incrementCipherDeletedCountCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementTOTPCountCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFavoriteItemCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addNoFolderItemCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCipherTypeCountCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertNotNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns `nil` when no ciphers passed.
    func test_prepareGroupData_noCiphers() async throws {
        let result = try await subject.prepareGroupData(
            from: [],
            collections: [],
            folders: [],
            filter: VaultListFilter()
        )
        XCTAssertNil(result)
    }
}
