import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CollectionServiceTests: XCTestCase {
    // MARK: Properties

    var collectionDataStore: MockCollectionDataStore!
    var subject: CollectionService!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        collectionDataStore = MockCollectionDataStore()
        stateService = MockStateService()

        subject = DefaultCollectionService(
            collectionDataStore: collectionDataStore,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        collectionDataStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `fetchAll(includeReadOnly:)` returns all collections, excluding those that are read-only.
    func test_fetchAll() async throws {
        let collections: [Collection] = [
            .fixture(id: "1", name: "Collection 1"),
            .fixture(id: "2", name: "Collection 2"),
            .fixture(id: "3", name: "Collection 3", readOnly: true),
        ]

        collectionDataStore.fetchAllCollectionsResult = .success(collections)
        stateService.activeAccount = .fixture()

        let fetchedCollections = try await subject.fetchAllCollections(includeReadOnly: false)

        XCTAssertEqual(
            fetchedCollections,
            [
                .fixture(id: "1", name: "Collection 1"),
                .fixture(id: "2", name: "Collection 2"),
            ]
        )
    }

    /// `fetchAll(includeReadOnly:)` returns all collections, including those that are read-only.
    func test_fetchAll_includeReadOnly() async throws {
        let collections: [Collection] = [
            .fixture(id: "1", name: "Collection 1"),
            .fixture(id: "2", name: "Collection 2"),
            .fixture(id: "3", name: "Collection 3", readOnly: true),
        ]

        collectionDataStore.fetchAllCollectionsResult = .success(collections)
        stateService.activeAccount = .fixture()

        let fetchedCollections = try await subject.fetchAllCollections(includeReadOnly: true)

        XCTAssertEqual(fetchedCollections, collections)
    }

    /// `replaceCollections(_:userId:)` replaces the persisted collections in the data store.
    func test_replaceCollections() async throws {
        let collections: [CollectionDetailsResponseModel] = [
            CollectionDetailsResponseModel.fixture(id: "1", name: "Collection 1"),
            CollectionDetailsResponseModel.fixture(id: "2", name: "Collection 2"),
        ]

        try await subject.replaceCollections(collections, userId: "1")

        XCTAssertEqual(collectionDataStore.replaceCollectionsValue, collections.map(Collection.init))
        XCTAssertEqual(collectionDataStore.replaceCollectionsUserId, "1")
    }
}
