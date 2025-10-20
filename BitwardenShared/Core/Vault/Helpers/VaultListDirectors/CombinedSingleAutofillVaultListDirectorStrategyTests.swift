import XCTest

@testable import BitwardenShared

// MARK: - CombinedSingleAutofillVaultListDirectorStrategyTests

class CombinedSingleAutofillVaultListDirectorStrategyTests: BitwardenTestCase { // swiftlint:disable:this type_name
    // MARK: Properties

    var cipherService: MockCipherService!
    var mockCallOrderHelper: MockCallOrderHelper!
    var subject: CombinedSingleAutofillVaultListDirectorStrategy!
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

        subject = CombinedSingleAutofillVaultListDirectorStrategy(
            builderFactory: vaultListSectionsBuilderFactory,
            cipherService: cipherService,
            vaultListDataPreparator: vaultListDataPreparator,
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

    /// `build(filter:)` returns empty when preparing data fails to return data.
    func test_build_returnsEmptyWhenPreparingDataFailsToReturnData() async throws {
        cipherService.ciphersSubject.value = [.fixture()]

        vaultListDataPreparator.prepareAutofillCombinedSingleDataReturnValue = nil

        var iteratorPublisher = try await subject.build(filter: VaultListFilter()).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns the sections built for combined single section autofill.
    func test_build_returnsSectionsBuiltForCombinedSingleSectionAutofill() async throws {
        cipherService.ciphersSubject.value = [.fixture()]

        vaultListDataPreparator.prepareAutofillCombinedSingleDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ],
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                mode: .combinedSingleSection,
            ),
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addAutofillCombinedSingleSection",
        ])
    }
}
