import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CollectionServiceTests: XCTestCase {
    // MARK: Properties

    var collectionDataStore: MockCollectionDataStore!
    var subject: CollectionService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        collectionDataStore = MockCollectionDataStore()

        subject = DefaultCollectionService(
            collectionDataStore: collectionDataStore,
            stateService: MockStateService()
        )
    }

    override func tearDown() {
        super.tearDown()

        collectionDataStore = nil
        subject = nil
    }

    // MARK: Tests

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
