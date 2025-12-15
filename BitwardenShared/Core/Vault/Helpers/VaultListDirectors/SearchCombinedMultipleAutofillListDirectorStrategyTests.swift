import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SearchCombinedMultipleAutofillListDirectorStrategyTests

class SearchCombinedMultipleAutofillListDirectorStrategyTests: BitwardenTestCase {
    // swiftlint:disable:previous type_name

    // MARK: Properties

    var cipherService: MockCipherService!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var mockCallOrderHelper: MockCallOrderHelper!
    var subject: SearchCombinedMultipleAutofillListDirectorStrategy!
    var vaultListDataPreparator: MockVaultListDataPreparator!
    var vaultListSectionsBuilder: MockVaultListSectionsBuilder!
    var vaultListSectionsBuilderFactory: MockVaultListSectionsBuilderFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        fido2UserInterfaceHelper = MockFido2UserInterfaceHelper()
        vaultListDataPreparator = MockVaultListDataPreparator()

        vaultListSectionsBuilder = MockVaultListSectionsBuilder()
        mockCallOrderHelper = vaultListSectionsBuilder.setUpCallOrderHelper()
        vaultListSectionsBuilderFactory = MockVaultListSectionsBuilderFactory()
        vaultListSectionsBuilderFactory.makeReturnValue = vaultListSectionsBuilder

        subject = SearchCombinedMultipleAutofillListDirectorStrategy(
            builderFactory: vaultListSectionsBuilderFactory,
            cipherService: cipherService,
            fido2UserInterfaceHelper: fido2UserInterfaceHelper,
            vaultListDataPreparator: vaultListDataPreparator,
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        fido2UserInterfaceHelper = nil
        mockCallOrderHelper = nil
        vaultListDataPreparator = nil
        vaultListSectionsBuilder = nil
        vaultListSectionsBuilderFactory = nil
        subject = nil
    }

    // MARK: Tests

    /// `build(filter:)` returns empty vault list data when there are no ciphers.
    @MainActor
    func test_build_emptyCiphers() async throws {
        cipherService.ciphersSubject.value = []
        fido2UserInterfaceHelper.credentialsForAuthenticationSubject.value = nil

        var iteratorPublisher = try await subject.build(filter: VaultListFilter()).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns empty when preparing search data fails to return data.
    @MainActor
    func test_build_returnsEmptyWhenPreparingSearchDataFailsToReturnData() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        fido2UserInterfaceHelper.credentialsForAuthenticationSubject.value = nil

        vaultListDataPreparator.prepareSearchAutofillCombinedMultipleDataReturnValue = nil

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(searchText: "test"),
        ).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns empty when preparing search data fails to return data with Fido2 credentials.
    @MainActor
    func test_build_returnsEmptyWhenPreparingSearchDataFailsToReturnDataWithFido2Credentials() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        fido2UserInterfaceHelper.credentialsForAuthenticationSubject.value = [.fixture()]

        vaultListDataPreparator.prepareSearchAutofillCombinedMultipleDataReturnValue = nil

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(rpID: "example.com", searchText: "test"),
        ).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` passes the correct rpID and search text to the sections builder.
    @MainActor
    func test_build_passesRPIDAndSearchTextToSectionsBuilder() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        fido2UserInterfaceHelper.credentialsForAuthenticationSubject.value = nil

        vaultListDataPreparator.prepareSearchAutofillCombinedMultipleDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData()

        let rpID = "example.com"
        let searchText = "test query"
        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(rpID: rpID, searchText: searchText),
        ).makeAsyncIterator()
        _ = try await iteratorPublisher.next()

        XCTAssertEqual(
            vaultListSectionsBuilder.addAutofillCombinedMultipleSectionReceivedArguments?.searchText,
            searchText,
        )
        XCTAssertEqual(
            vaultListSectionsBuilder.addAutofillCombinedMultipleSectionReceivedArguments?.rpID,
            rpID,
        )
    }
}
