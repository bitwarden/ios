import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - MainVaultListDirectorStrategyTests

class MainVaultListDirectorStrategyTests: BitwardenTestCase {
    // MARK: Properties

    var cipherService: MockCipherService!
    var collectionService: MockCollectionService!
    var folderService: MockFolderService!
    var mockCallOrderHelper: MockCallOrderHelper!
    var subject: MainVaultListDirectorStrategy!
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

        subject = MainVaultListDirectorStrategy(
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

        vaultListDataPreparator.prepareDataReturnValue = nil

        var iteratorPublisher = try await subject.build(filter: VaultListFilter()).makeAsyncIterator()
        let vaultListData = try await iteratorPublisher.next()

        XCTAssertEqual(vaultListData, VaultListData())
    }

    /// `build(filter:)` returns the sections built adding TOTP group and trash group as indicated by the filter.
    func test_build_returnsSectionsBuilt() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        collectionService.collectionsSubject.value = []
        folderService.foldersSubject.value = []

        vaultListDataPreparator.prepareDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ]
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                addTOTPGroup: true,
                addTrashGroup: true
            )
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addTOTPSection",
            "addFavoritesSection",
            "addTypesSection",
            "addFoldersSection",
            "addCollectionsSection",
            "addCipherDecryptionFailureIds",
            "addTrashSection",
        ])
    }

    /// `build(filter:)` returns the sections built adding TOTP group but not trash group as indicated by the filter.
    func test_build_returnsSectionsBuiltWithTOTPGroupButNoTrash() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        collectionService.collectionsSubject.value = []
        folderService.foldersSubject.value = []

        vaultListDataPreparator.prepareDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ]
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                addTOTPGroup: true,
                addTrashGroup: false
            )
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addTOTPSection",
            "addFavoritesSection",
            "addTypesSection",
            "addFoldersSection",
            "addCollectionsSection",
            "addCipherDecryptionFailureIds",
        ])
    }

    /// `build(filter:)` returns the sections built not adding TOTP group but adding trash group
    /// as indicated by the filter.
    func test_build_returnsSectionsBuiltWithoutTOTPGroupButWithTrash() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        collectionService.collectionsSubject.value = []
        folderService.foldersSubject.value = []

        vaultListDataPreparator.prepareDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ]
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                addTOTPGroup: false,
                addTrashGroup: true
            )
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addFavoritesSection",
            "addTypesSection",
            "addFoldersSection",
            "addCollectionsSection",
            "addCipherDecryptionFailureIds",
            "addTrashSection",
        ])
    }

    /// `build(filter:)` returns the sections built not adding TOTP group nor trash group as indicated by the filter.
    func test_build_returnsSectionsBuiltWithoutTOTPGroupNorTrash() async throws {
        cipherService.ciphersSubject.value = [.fixture()]
        collectionService.collectionsSubject.value = []
        folderService.foldersSubject.value = []

        vaultListDataPreparator.prepareDataReturnValue = VaultListPreparedData()

        vaultListSectionsBuilder.buildReturnValue = VaultListData(
            sections: [
                VaultListSection(id: "TestID1", items: [.fixture()], name: "Test1"),
                VaultListSection(id: "TestID2", items: [.fixture()], name: "Test2"),
                VaultListSection(id: "TestID3", items: [.fixture()], name: "Test3"),
            ]
        )

        var iteratorPublisher = try await subject.build(
            filter: VaultListFilter(
                addTOTPGroup: false,
                addTrashGroup: false
            )
        ).makeAsyncIterator()
        let result = try await iteratorPublisher.next()
        let vaultListData = try XCTUnwrap(result)

        XCTAssertEqual(vaultListData.sections.map(\.id), ["TestID1", "TestID2", "TestID3"])
        XCTAssertEqual(mockCallOrderHelper.callOrder, [
            "addFavoritesSection",
            "addTypesSection",
            "addFoldersSection",
            "addCollectionsSection",
            "addCipherDecryptionFailureIds",
        ])
    }
}
