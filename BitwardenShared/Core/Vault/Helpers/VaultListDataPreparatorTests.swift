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
    var mockCallOrderHelper: MockCallOrderHelper!
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
        mockCallOrderHelper = vaultListPreparedDataBuilder.setUpCallOrderHelper()
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
        mockCallOrderHelper = nil
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
            "incrementTOTPCount",
            "addFolderItem",
            "addFavoriteItem",
            "addNoFolderItem",
            "incrementCipherTypeCount",
            "incrementCollectionCount",
        ])
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
            "addFolderItem",
            "addFavoriteItem",
            "addNoFolderItem",
            "incrementCipherTypeCount",
            "incrementCollectionCount",
        ])
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
        ])
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
        ])
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
            "incrementCipherDeletedCount",
        ])
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
        XCTAssertTrue(mockCallOrderHelper.callOrder.isEmpty)
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
        ])
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
        ])
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
            "addFolderItem",
            "addItemForGroup",
        ])
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
            "incrementCollectionCount",
            "addItemForGroup",
        ])
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
            mockCallOrderHelper.reset()
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

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareFolders",
            "prepareCollections",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }
}
