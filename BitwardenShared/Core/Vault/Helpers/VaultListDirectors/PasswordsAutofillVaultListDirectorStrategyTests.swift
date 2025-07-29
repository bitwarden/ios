import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - PasswordsAutofillVaultListDirectorStrategyTests

class PasswordsAutofillVaultListDirectorStrategyTests: BitwardenTestCase {
    // swiftlint:disable:previous type_name

    // MARK: Properties

    var cipherService: MockCipherService!
    var mockCallOrderHelper: MockCallOrderHelper!
    var subject: PasswordsAutofillVaultListDirectorStrategy!
    var vaultListDataPreparator: MockVaultListDataPreparator!
    var vaultListSectionsBuilder: MockVaultListSectionsBuilder!
    var vaultListSectionsBuilderFactory: MockVaultListSectionsBuilderFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        vaultListDataPreparator = MockVaultListDataPreparator()

        vaultListSectionsBuilder = MockVaultListSectionsBuilder()
        mockCallOrderHelper = vaultListSectionsBuilder.setUpCallOrderHelper()
        vaultListSectionsBuilderFactory = MockVaultListSectionsBuilderFactory()
        vaultListSectionsBuilderFactory.makeReturnValue = vaultListSectionsBuilder

        subject = PasswordsAutofillVaultListDirectorStrategy(
            builderFactory: vaultListSectionsBuilderFactory,
            cipherService: cipherService,
            vaultListDataPreparator: vaultListDataPreparator
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        mockCallOrderHelper = nil
        vaultListDataPreparator = nil
        vaultListSectionsBuilder = nil
        vaultListSectionsBuilderFactory = nil
        subject = nil
    }

    // MARK: Tests

    /// `build(filter:)` returns empty when there are no ciphers.
    func test_build_returnsEmptyWhenNoCiphers() async throws {
        cipherService.ciphersSubject.value = []

        var iteratorPublisher = try await subject.build(filter: VaultListFilter()).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns empty when preparing data fails to return data.
    func test_build_returnsEmptyWhenPreparingDataFailsToReturnData() async throws {
        cipherService.ciphersSubject.value = [.fixture()]

        vaultListDataPreparator.prepareGroupDataReturnValue = nil

        var iteratorPublisher = try await subject.build(filter: VaultListFilter()).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns the sections built for passwords autofill.
    func test_build_returnsSectionsBuiltForPasswordsAutofill() async throws {
        cipherService.ciphersSubject.value = [.fixture()]

        vaultListDataPreparator.prepareAutofillPasswordsDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ]
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                mode: .passwords
            )
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addAutofillPasswordsSection",
        ])
    }
}
