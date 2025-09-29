import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - MainVaultListGroupDirectorStrategyTests

class MainVaultListGroupDirectorStrategyTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var collectionService: MockCollectionService!
    var folderService: MockFolderService!
    var mockCallOrderHelper: MockCallOrderHelper!
    var subject: MainVaultListGroupDirectorStrategy!
    var vaultListDataPreparator: MockVaultListDataPreparator!
    var vaultListSectionsBuilder: MockVaultListSectionsBuilder!
    var vaultListSectionsBuilderFactory: MockVaultListSectionsBuilderFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cipherService = MockCipherService()
        collectionService = MockCollectionService()
        folderService = MockFolderService()
        vaultListDataPreparator = MockVaultListDataPreparator()

        vaultListSectionsBuilder = MockVaultListSectionsBuilder()
        mockCallOrderHelper = vaultListSectionsBuilder.setUpCallOrderHelper()
        vaultListSectionsBuilderFactory = MockVaultListSectionsBuilderFactory()
        vaultListSectionsBuilderFactory.makeReturnValue = vaultListSectionsBuilder

        subject = MainVaultListGroupDirectorStrategy(
            builderFactory: vaultListSectionsBuilderFactory,
            cipherService: cipherService,
            collectionService: collectionService,
            folderService: folderService,
            vaultListDataPreparator: vaultListDataPreparator
        )
    }

    override func tearDown() {
        super.tearDown()

        cipherService = nil
        collectionService = nil
        folderService = nil
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
        collectionService.collectionsSubject.value = []
        folderService.foldersSubject.value = []

        var iteratorPublisher = try await subject.build(filter: VaultListFilter()).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns empty when preparing data fails to return data.
    func test_build_returnsEmptyWhenPreparingDataFailsToReturnData() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        collectionService.collectionsSubject.value = []
        folderService.foldersSubject.value = []

        vaultListDataPreparator.prepareGroupDataReturnValue = nil

        var iteratorPublisher = try await subject.build(filter: VaultListFilter()).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns the sections built for login group.
    func test_build_returnsSectionsBuiltForLoginGroup() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        collectionService.collectionsSubject.value = []
        folderService.foldersSubject.value = []

        vaultListDataPreparator.prepareGroupDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ]
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                group: .login
            )
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addGroupSection",
        ])
    }

    /// `build(filter:)` returns the sections built for folder group.
    func test_build_returnsSectionsBuiltForFolderGroup() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        collectionService.collectionsSubject.value = []
        folderService.foldersSubject.value = []

        vaultListDataPreparator.prepareGroupDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ]
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                group: .folder(id: "1", name: "TestFolder")
            )
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addFoldersSection",
            "addGroupSection",
        ])
    }

    /// `build(filter:)` returns the sections built for collection group.
    func test_build_returnsSectionsBuiltForCollectionGroup() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        collectionService.collectionsSubject.value = []
        folderService.foldersSubject.value = []

        vaultListDataPreparator.prepareGroupDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ]
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                group: .collection(id: "1", name: "TestOrg", organizationId: "1")
            )
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addCollectionsSection",
            "addGroupSection",
        ])
    }
}
