// swiftlint:disable:this file_name

import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - VaultListDataPreparatorSearchTests

class VaultListDataPreparatorSearchTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cipherMatchingHelper: MockCipherMatchingHelper!
    var cipherMatchingHelperFactory: MockCipherMatchingHelperFactory!
    var ciphersClientWrapperService: MockCiphersClientWrapperService!
    var clientService: MockClientService!
    var configService: MockConfigService!
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

        cipherMatchingHelper = MockCipherMatchingHelper()
        cipherMatchingHelperFactory = MockCipherMatchingHelperFactory()
        cipherMatchingHelperFactory.makeReturnValue = cipherMatchingHelper

        ciphersClientWrapperService = MockCiphersClientWrapperService()
        clientService = MockClientService()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        policyService = MockPolicyService()
        stateService = MockStateService()

        vaultListPreparedDataBuilder = MockVaultListPreparedDataBuilder()
        mockCallOrderHelper = vaultListPreparedDataBuilder.setUpCallOrderHelper()
        vaultListPreparedDataBuilder.buildReturnValue = VaultListPreparedData()

        vaultListPreparedDataBuilderFactory = MockVaultListPreparedDataBuilderFactory()
        vaultListPreparedDataBuilderFactory.makeReturnValue = vaultListPreparedDataBuilder

        subject = DefaultVaultListDataPreparator(
            cipherMatchingHelperFactory: cipherMatchingHelperFactory,
            ciphersClientWrapperService: ciphersClientWrapperService,
            clientService: clientService,
            configService: configService,
            errorReporter: errorReporter,
            policyService: policyService,
            stateService: stateService,
            vaultListPreparedDataBuilderFactory: vaultListPreparedDataBuilderFactory,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherMatchingHelper = nil
        cipherMatchingHelperFactory = nil
        ciphersClientWrapperService = nil
        clientService = nil
        configService = nil
        errorReporter = nil
        mockCallOrderHelper = nil
        policyService = nil
        stateService = nil
        vaultListPreparedDataBuilder = nil
        vaultListPreparedDataBuilderFactory = nil
        subject = nil
    }

    // MARK: Tests

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns `nil`
    /// when no ciphers passed.
    func test_prepareSearchAutofillCombinedMultipleData_noCiphers() async throws {
        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: nil,
        )
        XCTAssertNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns `nil`
    /// when filter has no search text.
    func test_prepareSearchAutofillCombinedMultipleData_noSearchText() async throws {
        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [.fixture()],
            filter: VaultListFilter(),
            withFido2Credentials: nil,
        )
        XCTAssertNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns `nil`
    /// when filter has empty search text.
    func test_prepareSearchAutofillCombinedMultipleData_emptySearchText() async throws {
        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [.fixture()],
            filter: VaultListFilter(searchText: ""),
            withFido2Credentials: nil,
        )
        XCTAssertNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the
    /// prepared data for a login cipher matching search query without Fido2.
    func test_prepareSearchAutofillCombinedMultipleData_returnsPreparedDataForLoginNoFido2() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            login: .fixture(
                hasFido2: false,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            name: "Example Site",
            copyableFields: [.loginPassword],
        )

        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [
                .fixture(
                    login: .fixture(
                        fido2Credentials: [],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the
    /// prepared data for a login cipher with Fido2.
    func test_prepareSearchAutofillCombinedMultipleData_returnsPreparedDataForLoginWithFido2() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: true,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            name: "Example Site",
            copyableFields: [.loginPassword],
        )

        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [
                .fixture(
                    id: "1",
                    login: .fixture(
                        fido2Credentials: [.fixture()],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: [.fixture(id: "1")],
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addFido2Item",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the
    /// prepared data for a login cipher with Fido2 but no Fido2 credentials provided.
    func test_prepareSearchAutofillCombinedMultipleData_returnsDataWithFido2NoCredentialsProvided() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: true,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            name: "Example Site",
            copyableFields: [.loginPassword],
        )

        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [
                .fixture(
                    id: "1",
                    login: .fixture(
                        fido2Credentials: [.fixture()],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the
    /// prepared data for a login cipher with Fido2 but cipher ID doesn't match credentials.
    func test_prepareSearchAutofillCombinedMultipleData_returnsDataWithFido2NonMatchingCredentials() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: true,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            name: "Example Site",
            copyableFields: [.loginPassword],
        )

        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [
                .fixture(
                    id: "1",
                    login: .fixture(
                        fido2Credentials: [.fixture()],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: [.fixture(id: "2")],
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the
    /// prepared data filtering out cipher as it doesn't pass restrict item type policy.
    @MainActor
    func test_prepareSearchAutofillCombinedMultipleData_doesNotPassRestrictItemPolicy() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            type: .card(.fixture()),
        )
        policyService.policyAppliesToUserPolicies = [
            .fixture(organizationId: "1"),
        ]

        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [
                .fixture(type: .card),
            ],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the
    /// prepared data filtering out cipher as it's deleted.
    @MainActor
    func test_prepareSearchAutofillCombinedMultipleData_deletedCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = nil

        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [
                .fixture(
                    deletedDate: .now,
                    login: .fixture(
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterCallCount, 1)
        XCTAssertEqual(
            try ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterResult.get().count,
            0,
            "Deleted cipher should be filtered out by preFilter",
        )
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherCallCount, 0)
        XCTAssertNotNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the
    /// prepared data filtering out cipher as it's not a login type.
    /// Note: Without a group filter, the preFilter doesn't filter by type, so the cipher gets decrypted
    /// but is then filtered out in the onCipher logic.
    @MainActor
    func test_prepareSearchAutofillCombinedMultipleData_nonLoginCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            name: "Example Card",
            type: .card(.fixture()),
        )

        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [
                .fixture(type: .card),
            ],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterCallCount, 1)
        XCTAssertEqual(
            try ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterResult.get().count,
            1,
            "Non-login cipher should pass preFilter when no group filter is set",
        )
        XCTAssertEqual(
            ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherCallCount,
            1,
            "onCipher should be called even for non-login ciphers",
        )
        XCTAssertNotNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the
    /// prepared data filtering out cipher as it doesn't have any copyable login fields.
    @MainActor
    func test_prepareSearchAutofillCombinedMultipleData_noCopyableLoginFields() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: false,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            name: "Example Site",
            copyableFields: [],
        )

        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareSearchAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the
    /// prepared data filtering out cipher as it doesn't match the search query.
    @MainActor
    func test_prepareSearchAutofillCombinedMultipleData_nonMatchingSearchQuery() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: false,
                uris: [.fixture(uri: "https://other.com", match: .exact)],
            ),
            name: "Other Site",
            copyableFields: [.loginPassword],
        )

        let result = await subject.prepareSearchAutofillCombinedMultipleData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://other.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(searchText: "example"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns `nil` when no ciphers passed.
    func test_prepareSearchData_noCiphers() async throws {
        let result = await subject.prepareSearchData(
            from: [],
            filter: VaultListFilter(searchText: "example"),
        )
        XCTAssertNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns `nil` when filter has no search text.
    func test_prepareSearchData_noSearchText() async throws {
        let result = await subject.prepareSearchData(
            from: [.fixture()],
            filter: VaultListFilter(),
        )
        XCTAssertNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns `nil` when filter has empty search text.
    func test_prepareSearchData_emptySearchText() async throws {
        let result = await subject.prepareSearchData(
            from: [.fixture()],
            filter: VaultListFilter(searchText: ""),
        )
        XCTAssertNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns the prepared data for a cipher matching search query.
    func test_prepareSearchData_returnsPreparedData() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            name: "Example Site",
        )

        let result = await subject.prepareSearchData(
            from: [.fixture()],
            filter: VaultListFilter(searchText: "example"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addSearchResultItem",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns the prepared data filtering out cipher
    /// as it doesn't pass restrict item type policy.
    @MainActor
    func test_prepareSearchData_doesNotPassRestrictItemPolicy() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            type: .card(.fixture()),
        )
        policyService.policyAppliesToUserPolicies = [
            .fixture(organizationId: "1"),
        ]

        let result = await subject.prepareSearchData(
            from: [.fixture(type: .card)],
            filter: VaultListFilter(searchText: "example"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns the prepared data filtering out cipher
    /// as it's deleted and filter group is not trash.
    @MainActor
    func test_prepareSearchData_deletedCipherNotTrashGroup() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = nil

        let result = await subject.prepareSearchData(
            from: [.fixture(deletedDate: .now)],
            filter: VaultListFilter(group: .login, searchText: "example"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterCallCount, 1)
        XCTAssertEqual(
            try ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterResult.get().count,
            0,
            "Deleted cipher should be filtered out by preFilter when group is not trash",
        )
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherCallCount, 0)
        XCTAssertNotNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns the prepared data including deleted cipher
    /// when filter group is trash.
    @MainActor
    func test_prepareSearchData_deletedCipherTrashGroup() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            name: "Example Site",
            deletedDate: .now,
        )

        let result = await subject.prepareSearchData(
            from: [.fixture(deletedDate: .now)],
            filter: VaultListFilter(group: .trash, searchText: "example"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addSearchResultItem",
        ])
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterCallCount, 1)
        XCTAssertEqual(
            try ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterResult.get().count,
            1,
            "Deleted cipher should pass preFilter when group is trash",
        )
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherCallCount, 1)
        XCTAssertNotNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns the prepared data filtering out cipher
    /// as it doesn't belong to the filter group.
    @MainActor
    func test_prepareSearchData_cipherDoesNotBelongToGroup() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = nil

        let result = await subject.prepareSearchData(
            from: [.fixture(type: .card)],
            filter: VaultListFilter(group: .login, searchText: "example"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterCallCount, 1)
        XCTAssertEqual(
            try ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterResult.get().count,
            0,
            "Card cipher should be filtered out by preFilter when group is login",
        )
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherCallCount, 0)
        XCTAssertNotNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns the prepared data including cipher
    /// when it belongs to the filter group.
    @MainActor
    func test_prepareSearchData_cipherBelongsToGroup() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            name: "Example Login",
            type: .login(.fixture()),
        )

        let result = await subject.prepareSearchData(
            from: [.fixture(login: .fixture(), type: .login)],
            filter: VaultListFilter(group: .login, searchText: "example"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addSearchResultItem",
        ])
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterCallCount, 1)
        XCTAssertEqual(
            try ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterResult.get().count,
            1,
            "Login cipher should pass preFilter when group is login",
        )
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherCallCount, 1)
        XCTAssertNotNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns the prepared data for all ciphers
    /// when no group filter is specified.
    @MainActor
    func test_prepareSearchData_noGroupFilter() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            name: "Example Card",
            type: .card(.fixture()),
        )

        let result = await subject.prepareSearchData(
            from: [.fixture(type: .card)],
            filter: VaultListFilter(searchText: "example"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addSearchResultItem",
        ])
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterCallCount, 1)
        XCTAssertEqual(
            try ciphersClientWrapperService.decryptAndProcessCiphersInBatchPreFilterResult.get().count,
            1,
            "Card cipher should pass preFilter when no group filter is specified",
        )
        XCTAssertEqual(ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherCallCount, 1)
        XCTAssertNotNil(result)
    }

    /// `prepareSearchData(from:filter:)` returns the prepared data filtering out cipher
    /// as it doesn't match the search query.
    @MainActor
    func test_prepareSearchData_nonMatchingSearchQuery() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            name: "Other Site",
        )

        let result = await subject.prepareSearchData(
            from: [.fixture()],
            filter: VaultListFilter(searchText: "nonexistent"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addSearchResultItem",
        ])
        XCTAssertNotNil(result)
    }
} // swiftlint:disable:this file_length
