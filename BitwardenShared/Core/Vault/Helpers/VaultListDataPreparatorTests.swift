import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - VaultListDataPreparatorTests

class VaultListDataPreparatorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
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

    /// `prepareAutofillCombinedSingleData(from:filter:)` returns `nil` when no ciphers passed.
    func test_prepareAutofillCombinedSingleData_noCiphers() async throws {
        let result = await subject.prepareAutofillCombinedSingleData(
            from: [],
            filter: VaultListFilter(uri: "https://example.com"),
        )
        XCTAssertNil(result)
    }

    /// `prepareAutofillCombinedSingleData(from:filter:)` returns `nil` when filter passed doesn't
    /// have the URI to filter.
    func test_prepareAutofillCombinedSingleData_noFilterUri() async throws {
        let result = await subject.prepareAutofillCombinedSingleData(
            from: [.fixture()],
            filter: VaultListFilter(),
        )
        XCTAssertNil(result)
    }

    /// `prepareAutofillCombinedSingleData(from:filter:)` returns the prepared data for a cipher
    /// with login and no Fido2.
    func test_prepareAutofillCombinedSingleData_returnsPreparedDataForLoginNoFido2() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            login: .fixture(
                hasFido2: false,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            copyableFields: [.loginPassword],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedSingleData(
            from: [
                .fixture(
                    login: .fixture(
                        fido2Credentials: [],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedSingleData(from:filter:)` returns the prepared data for a cipher with login and Fido2,
    /// adding it only to Fido2 items (not to group items, unlike the multiple mode).
    func test_prepareAutofillCombinedSingleData_returnsPreparedDataForLoginWithFido2() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            login: .fixture(
                hasFido2: true,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            copyableFields: [.loginPassword],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedSingleData(
            from: [
                .fixture(
                    login: .fixture(
                        fido2Credentials: [.fixture()],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addFido2Item",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedSingleData(from:filter:)` returns the prepared data filtering out
    /// cipher as it doesn't pass restrict item type policy.
    @MainActor
    func test_prepareAutofillCombinedSingleData_doesNotPassRestrictItemPolicy() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            type: .card(.fixture()),
        )
        policyService.policyAppliesToUserPolicies = [
            .fixture(organizationId: "1"),
        ]
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedSingleData(
            from: [
                .fixture(type: .card),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedSingleData(from:filter:)` returns the prepared data including
    /// ciphers without copyable login fields.
    @MainActor
    func test_prepareAutofillCombinedSingleData_noCopyableLoginFields() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: false,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            copyableFields: [],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedSingleData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedSingleData(from:filter:)` returns the prepared data filtering out
    /// cipher as it's deleted.
    @MainActor
    func test_prepareAutofillCombinedSingleData_deletedCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            deletedDate: .now,
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedSingleData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns `nil` when no ciphers passed.
    func test_prepareAutofillCombinedMultipleData_noCiphers() async throws {
        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: nil,
        )
        XCTAssertNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns `nil`
    /// when filter passed doesn't have the URI to filter.
    func test_prepareAutofillCombinedMultipleData_noFilterUri() async throws {
        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [.fixture()],
            filter: VaultListFilter(),
            withFido2Credentials: nil,
        )
        XCTAssertNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the prepared data for a cipher
    /// with login and no Fido2.
    func test_prepareAutofillCombinedMultipleData_returnsPreparedDataForLoginNoFido2() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            login: .fixture(
                hasFido2: false,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            copyableFields: [.loginPassword],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [
                .fixture(
                    login: .fixture(
                        fido2Credentials: [],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the prepared data for a cipher
    /// with login and Fido2.
    func test_prepareAutofillCombinedMultipleData_returnsPreparedDataForLoginWithFido2() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: true,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            copyableFields: [.loginPassword],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [
                .fixture(
                    id: "1",
                    login: .fixture(
                        fido2Credentials: [.fixture()],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: [.fixture(id: "1")],
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addFido2Item",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the prepared data for a cipher
    /// with login and Fido2 but no Fido2 credentials provided.
    func test_prepareAutofillCombinedMultipleData_returnsDataWithFido2NoCredentialsProvided() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: true,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            copyableFields: [.loginPassword],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [
                .fixture(
                    id: "1",
                    login: .fixture(
                        fido2Credentials: [.fixture()],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the prepared data for a cipher
    /// with login and Fido2 but cipher ID doesn't match credentials.
    func test_prepareAutofillCombinedMultipleData_returnsDataWithFido2NonMatchingCredentials() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: true,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            copyableFields: [.loginPassword],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [
                .fixture(
                    id: "1",
                    login: .fixture(
                        fido2Credentials: [.fixture()],
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: [.fixture(id: "2")],
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the prepared data filtering out
    /// cipher as it doesn't pass restrict item type policy.
    @MainActor
    func test_prepareAutofillCombinedMultipleData_doesNotPassRestrictItemPolicy() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            type: .card(.fixture()),
        )
        policyService.policyAppliesToUserPolicies = [
            .fixture(organizationId: "1"),
        ]
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [
                .fixture(type: .card),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the prepared data filtering out
    /// cipher as it's deleted.
    @MainActor
    func test_prepareAutofillCombinedMultipleData_deletedCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            deletedDate: .now,
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the prepared data filtering out
    /// cipher as it's not a login type.
    @MainActor
    func test_prepareAutofillCombinedMultipleData_nonLoginCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            type: .card(.fixture()),
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [
                .fixture(type: .card),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the prepared data filtering out
    /// cipher as it doesn't have any copyable login fields.
    @MainActor
    func test_prepareAutofillCombinedMultipleData_noCopyableLoginFields() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: false,
                uris: [.fixture(uri: "https://example.com", match: .exact)],
            ),
            copyableFields: [],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillCombinedMultipleData(from:filter:withFido2Credentials:)` returns the prepared data filtering out
    /// cipher as it doesn't match the URI.
    @MainActor
    func test_prepareAutofillCombinedMultipleData_nonMatchingCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            login: .fixture(
                hasFido2: false,
                uris: [.fixture(uri: "https://other.com", match: .exact)],
            ),
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = CipherMatchResult.none

        let result = await subject.prepareAutofillCombinedMultipleData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://other.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
            withFido2Credentials: nil,
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns `nil` when no ciphers passed.
    func test_prepareData_noCiphers() async throws {
        let result = await subject.prepareData(
            from: [],
            collections: [],
            folders: [],
            filter: VaultListFilter(),
        )
        XCTAssertNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns the prepared data without filtering out cipher.
    func test_prepareData_returnsPreparedDataNoFilteringOutCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture()

        let result = await subject.prepareData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(addTOTPGroup: true),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
            "incrementTOTPCount",
            "addCipherDecryptionFailure",
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

        let result = await subject.prepareData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(addTOTPGroup: false),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
            "addCipherDecryptionFailure",
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
            organizationId: "1",
        )

        let result = await subject.prepareData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(addTOTPGroup: true, filterType: .myVault),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when not passing restrict item types policy.
    @MainActor
    func test_prepareData_noPassingRestrictItemTypesPolicy() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            type: .card(.fixture()),
        )
        policyService.policyAppliesToUserPolicies = [.fixture(organizationId: "1")]

        let result = await subject.prepareData(
            from: [.fixture(organizationId: "1", type: .card)],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns the prepared data without filtering out cipher even
    /// with restricted item types policy without matching organization.
    @MainActor
    func test_prepareData_preparedDataNoFilteringOutCipherWithRestrictedItemsPolicyNonMatchingOrgs() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            organizationId: "1",
            type: .card(.fixture()),
        )

        policyService.policyAppliesToUserPolicies = [.fixture(organizationId: "2")]

        let result = await subject.prepareData(
            from: [.fixture(organizationId: "1", type: .card)],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(addTOTPGroup: true),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
            "incrementTOTPCount",
            "addCipherDecryptionFailure",
            "addFolderItem",
            "addFavoriteItem",
            "addNoFolderItem",
            "incrementCipherTypeCount",
            "incrementCollectionCount",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when having a deleted date, but incrementing the count of deleted items.
    func test_prepareData_withDeletedDate() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            deletedDate: .now,
        )

        let result = await subject.prepareData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
            "incrementCipherDeletedCount",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns `nil` when no ciphers passed.
    func test_prepareGroupData_noCiphers() async throws {
        let result = await subject.prepareGroupData(
            from: [],
            collections: [],
            folders: [],
            filter: VaultListFilter(),
        )
        XCTAssertTrue(mockCallOrderHelper.callOrder.isEmpty)
        XCTAssertNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when vault list filter is `.myVault` and the cipher belongs to an organization.
    func test_prepareGroupData_withMyVaultFilterAndBelongingToOrganization() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
        )

        let result = await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(filterType: .myVault, group: .login),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when not passing restrict item types policy.
    @MainActor
    func test_prepareGroupData_noPassingRestrictItemTypesPolicy() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            type: .card(.fixture()),
        )
        policyService.policyAppliesToUserPolicies = [.fixture(organizationId: "1")]

        let result = await subject.prepareGroupData(
            from: [.fixture(organizationId: "1", type: .card)],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: .login),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data filtering out cipher
    /// when deleted date is set and vault filter is not trash.
    @MainActor
    func test_prepareGroupData_cipherDeleteDateSet_vaultNotTrash() async throws {
        let result = await subject.prepareGroupData(
            from: [.fixture(deletedDate: .now)],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: .collection(id: "1", name: "Collection", organizationId: "1")),
        )

        // should not call incrementCollectionCount and addItemForGroup
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data
    /// adding folder items when filtering by folder.
    func test_prepareGroupData_folder() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
        )

        let result = await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: .folder(id: "1", name: "Folder")),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
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
            id: "1",
        )

        let result = await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: .collection(id: "1", name: "Collection", organizationId: "1")),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
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
            id: "1",
        )

        let groups: [VaultListGroup] = [.card, .identity, .login, .noFolder, .secureNote, .sshKey, .totp, .trash]
        for group in groups {
            mockCallOrderHelper.reset()
            try await prepareGroupDataGenericTest(group: group)
        }
    }

    /// `prepareGroupData(from:collections:folders:filter:)` returns the prepared data
    /// when not filtering by folder nor collection with restricted items policy
    /// non-matching organization IDs.
    @MainActor
    func test_prepareGroupData_cardNonMatchingRestrictedItemsTypeOrgs() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            type: .card(.fixture()),
        )
        policyService.policyAppliesToUserPolicies = [.fixture(organizationId: "2")]

        let result = await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: .card),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }

    /// `prepareAutofillPasswordsData(from::filter:)` returns `nil` when no ciphers passed.
    func test_prepareAutofillPasswordsData_noCiphers() async throws {
        let result = await subject.prepareAutofillPasswordsData(
            from: [],
            filter: VaultListFilter(),
        )
        XCTAssertNil(result)
    }

    /// `prepareAutofillPasswordsData(from::filter:)` returns `nil` when filter passed doesn't
    /// have the URI to filter.
    func test_prepareAutofillPasswordsData_noLoginUris() async throws {
        let result = await subject.prepareAutofillPasswordsData(
            from: [.fixture()],
            filter: VaultListFilter(),
        )
        XCTAssertNil(result)
    }

    /// `prepareAutofillPasswordsData(from:filter:)` returns the prepared data without filtering out cipher.
    func test_prepareAutofillPasswordsData_returnsPreparedDataNoFilteringOutCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            copyableFields: [.loginPassword],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillPasswordsData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                    type: .login,
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "addItemWithMatchResultCipher",
        ])
        XCTAssertNotNil(result)
        XCTAssertEqual(cipherMatchingHelper.doesCipherMatchReceivedCipher?.id, "1")
    }

    /// `prepareAutofillPasswordsData(from:filter:)` returns the prepared data filtering out cipher as it doesn't pass
    /// restrict item type policy.
    @MainActor
    func test_prepareAutofillPasswordsData_doesNotPassRestrictItemPolicy() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            organizationId: "1",
            type: .card(.fixture()),
        )
        policyService.policyAppliesToUserPolicies = [
            .fixture(organizationId: "1"),
        ]
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillPasswordsData(
            from: [
                .fixture(
                    type: .card,
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
        XCTAssertNil(cipherMatchingHelper.doesCipherMatchReceivedCipher)
    }

    /// `prepareAutofillPasswordsData(from:filter:)` returns the prepared data filtering out cipher
    /// as it doesn't have any copyable login fields.
    @MainActor
    func test_prepareAutofillPasswordsData_noCopyableLoginFields() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            copyableFields: [],
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillPasswordsData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
        XCTAssertNil(cipherMatchingHelper.doesCipherMatchReceivedCipher)
    }

    /// `prepareAutofillPasswordsData(from:filter:)` returns the prepared data filtering out cipher as it's deleted.
    @MainActor
    func test_prepareAutofillPasswordsData_deletedCipher() async throws {
        ciphersClientWrapperService.decryptAndProcessCiphersInBatchOnCipherParameterToPass = .fixture(
            id: "1",
            deletedDate: .now,
        )
        cipherMatchingHelper.doesCipherMatchReturnValue = .exact

        let result = await subject.prepareAutofillPasswordsData(
            from: [
                .fixture(
                    login: .fixture(
                        uris: [.fixture(uri: "https://example.com", match: .exact)],
                    ),
                ),
            ],
            filter: VaultListFilter(uri: "https://example.com"),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
        ])
        XCTAssertNotNil(result)
        XCTAssertNil(cipherMatchingHelper.doesCipherMatchReceivedCipher)
    }

    // MARK: Private

    /// Tests `prepareGroupData(from:collections:folders:filter:)` generically for most groups.
    /// - Parameter group: The group to test.
    private func prepareGroupDataGenericTest(group: VaultListGroup) async throws {
        let result = await subject.prepareGroupData(
            from: [.fixture()],
            collections: [.fixture(id: "1"), .fixture(id: "2")],
            folders: [.fixture(id: "1"), .fixture(id: "2"), .fixture(id: "3")],
            filter: VaultListFilter(group: group),
        )

        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "prepareRestrictItemsPolicyOrganizations",
            "prepareFolders",
            "prepareCollections",
            "addItemForGroup",
        ])
        XCTAssertNotNil(result)
    }
} // swiftlint:disable:this file_length
