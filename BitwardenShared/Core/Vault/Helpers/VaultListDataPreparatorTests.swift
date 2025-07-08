import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - VaultListDataPreparatorTests

class VaultListDataPreparatorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var ciphersClientWrapperService: MockCiphersClientWrapperService!
    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var policyService: MockPolicyService!
    var stateService: MockStateService!
    var subject: VaultListDataPreparator!
    var vaultListPreparedDataBuilder: MockVaultListPreparedDataBuilder!
    var vaultListPreparedDataBuilderFactory: MockVaultListPreparedDataBuilderFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        ciphersClientWrapperService = MockCiphersClientWrapperService()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        policyService = MockPolicyService()
        stateService = MockStateService()

        vaultListPreparedDataBuilder = MockVaultListPreparedDataBuilder()
        vaultListPreparedDataBuilder.setUpFluentReturn()
        vaultListPreparedDataBuilder.buildReturnValue = VaultListPreparedData()

        vaultListPreparedDataBuilderFactory = MockVaultListPreparedDataBuilderFactory()
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

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when vault list filter is `.myVault` and the cipher belongs to an organization.
    func test_prepareGroupData_withMyVaultFilterAndBelongingToOrganization() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1"
        )

        let result = try await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(filterType: .myVault, group: .login)
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addItemForGroupWithCalled)
        XCTAssertNotNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when not passing restrict item types policy.
    func test_prepareGroupData_noPassingRestrictItemTypesPolicy() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1"
        )
        policyService.passesRestrictItemTypesPolicyResult = false

        let result = try await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: .login)
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addItemForGroupWithCalled)
        XCTAssertNotNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data
    /// adding folder items when filtering by folder.
    func test_prepareGroupData_folder() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1"
        )

        let result = try await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: .folder(id: "1", name: "Folder"))
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addItemForGroupWithCalled)
        XCTAssertNotNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data
    /// adding incrementing collection count when filtering by collection.
    func test_prepareGroupData_collection() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1"
        )

        let result = try await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: .collection(id: "1", name: "Collection", organizationId: "1"))
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addItemForGroupWithCalled)
        XCTAssertNotNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data
    /// when not filtering by folder nor collection.
    func test_prepareGroupData_nonFolderNonCollection() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1"
        )

        let groups: [VaultListGroup] = [.card, .identity, .login, .noFolder, .secureNote, .sshKey, .totp, .trash]
        for group in groups {
            try await prepareGroupDataGenericTest(group: group)
        }
    }

    // MARK: Private

    /// Tests `prepareGroupData(from:collections:folders:filter:)` generically for most groups.
    /// - Parameter group: The group to test.
    private func prepareGroupDataGenericTest(group: VaultListGroup) async throws {
        let result = try await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: group)
        )

        XCTAssertTrue(vaultListPreparedDataBuilder.prepareFoldersFoldersFilterTypeCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.prepareCollectionsCollectionsFilterTypeCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.addFolderItemCipherFilterFoldersCalled)
        XCTAssertFalse(vaultListPreparedDataBuilder.incrementCollectionCountCipherCalled)
        XCTAssertTrue(vaultListPreparedDataBuilder.addItemForGroupWithCalled)
        XCTAssertNotNil(result)
    }
}
