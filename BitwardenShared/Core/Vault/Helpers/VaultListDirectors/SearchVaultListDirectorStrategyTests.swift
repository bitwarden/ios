import BitwardenSdk
import Combine
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SearchVaultListDirectorStrategyTests

class SearchVaultListDirectorStrategyTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var mockCallOrderHelper: MockCallOrderHelper!
    var subject: SearchVaultListDirectorStrategy!
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

        subject = SearchVaultListDirectorStrategy(
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

    /// `build(filter:)` returns empty vault list data when there are no ciphers.
    @MainActor
    func test_build_emptyCiphers() async throws {
        cipherService.ciphersSubject.value = []

        var iteratorPublisher = try await subject.build(
            filterPublisher: VaultListFilter().asPublisher(),
        ).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns empty when preparing search data fails to return data.
    @MainActor
    func test_build_returnsEmptyWhenPreparingSearchDataFailsToReturnData() async throws {
        cipherService.ciphersSubject.value = [.fixture()]

        vaultListDataPreparator.prepareSearchDataReturnValue = nil

        var iteratorPublisher = try await subject.build(
            filterPublisher: VaultListFilter(
                searchText: "test",
            ).asPublisher(),
        ).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns the search results sections built.
    @MainActor
    func test_build_returnsSectionsBuiltForSearch() async throws {
        cipherService.ciphersSubject.value = [.fixture()]

        vaultListDataPreparator.prepareSearchDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "SearchResults", items: [.fixture()], name: ""),
            ],
        )

        var iteratorPublisher = try await subject.build(
            filterPublisher: VaultListFilter(
                searchText: "test",
            ).asPublisher(),
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["SearchResults"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addSearchResultsSection",
        ])
    }
}
