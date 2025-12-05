import BitwardenSdk
import Combine
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - CombinedMultipleAutofillVaultListDirectorStrategyTests

class CombinedMultipleAutofillVaultListDirectorStrategyTests: BitwardenTestCase { // swiftlint:disable:this type_name
    // MARK: Properties

    var cipherService: MockCipherService!
    var fido2UserInterfaceHelper: MockFido2UserInterfaceHelper!
    var mockCallOrderHelper: MockCallOrderHelper!
    var subject: CombinedMultipleAutofillVaultListDirectorStrategy!
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

        subject = CombinedMultipleAutofillVaultListDirectorStrategy(
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

    /// `build(filter:)` returns empty when preparing data fails to return data.
    @MainActor
    func test_build_returnsEmptyWhenPreparingDataFailsToReturnData() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        fido2UserInterfaceHelper.credentialsForAuthenticationSubject.value = nil

        vaultListDataPreparator.prepareAutofillCombinedMultipleDataReturnValue = nil

        var iteratorPublisher = try await subject.build(filter: VaultListFilter()).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns empty when preparing data fails to return data with Fido2 credentials.
    @MainActor
    func test_build_returnsEmptyWhenPreparingDataFailsToReturnDataWithFido2Credentials() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        fido2UserInterfaceHelper.credentialsForAuthenticationSubject.value = [.fixture()]

        vaultListDataPreparator.prepareAutofillCombinedMultipleDataReturnValue = nil

        var iteratorPublisher = try await subject.build(filter: VaultListFilter()).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns the sections built for combined multiple sections autofill without Fido2 credentials.
    @MainActor
    func test_build_returnsSectionsBuiltForCombinedMultipleSectionsAutofillNoFido2() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        fido2UserInterfaceHelper.credentialsForAuthenticationSubject.value = nil

        vaultListDataPreparator.prepareAutofillCombinedMultipleDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
            ],
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                mode: .combinedMultipleSections,
            ),
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addAutofillCombinedMultipleSection",
        ])
    }

    /// `build(filter:)` returns the sections built for combined multiple sections autofill with Fido2 credentials.
    @MainActor
    func test_build_returnsSectionsBuiltForCombinedMultipleSectionsAutofillWithFido2() async throws {
        cipherService.ciphersSubject.value = [.fixture(id: "1")]
        let fido2Credentials: [CipherView] = [.fixture(id: "1"), .fixture(id: "2")]
        fido2UserInterfaceHelper.credentialsForAuthenticationSubject.value = fido2Credentials

        vaultListDataPreparator.prepareAutofillCombinedMultipleDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ],
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                mode: .combinedMultipleSections,
            ),
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addAutofillCombinedMultipleSection",
        ])
    }

    /// `build(filter:)` returns sections without Fido2 section when Fido2 credentials exist but rpID is nil.
    @MainActor
    func test_build_withFido2CredentialsButNilRpID_doesNotAddFido2Section() async throws {
        cipherService.ciphersSubject.value = [.fixture(id: "1")]
        let fido2Credentials: [CipherView] = [.fixture(id: "1"), .fixture(id: "2")]
        fido2UserInterfaceHelper.credentialsForAuthenticationSubject.value = fido2Credentials

        vaultListDataPreparator.prepareAutofillCombinedMultipleDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
            ],
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                mode: .combinedMultipleSections,
                rpID: nil,
            ),
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addAutofillCombinedMultipleSection",
        ])
    }
}
