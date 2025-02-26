import BitwardenSdk
import CoreData
import XCTest

@testable import BitwardenShared

class CollectionDataStoreTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DataStore!

    let collections = [
        Collection.fixture(id: "1", name: "COLLECTION1"),
        Collection.fixture(id: "2", name: "COLLECTION2"),
        Collection.fixture(id: "3", name: "COLLECTION3"),
    ]

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `collectionPublisher(userId:)` returns a publisher for a user's collection objects.
    func test_collectionPublisher() async throws {
        var publishedValues = [[Collection]]()
        let publisher = subject.collectionPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { values in
                    publishedValues.append(values)
                }
            )
        defer { publisher.cancel() }

        try await subject.replaceCollections(collections, userId: "1")

        waitFor { publishedValues.count == 2 }
        XCTAssertTrue(publishedValues[0].isEmpty)
        XCTAssertEqual(publishedValues[1], collections)
    }

    /// `deleteAllCollections(user:)` removes all objects for the user.
    func test_deleteAllCollections() async throws {
        try await insertCollections(collections, userId: "1")
        try await insertCollections(collections, userId: "2")

        try await subject.deleteAllCollections(userId: "1")

        try XCTAssertTrue(fetchCollections(userId: "1").isEmpty)
        try XCTAssertEqual(fetchCollections(userId: "2").count, 3)
    }

    /// `deleteCollection(id:userId:)` removes the collection with the given ID for the user.
    func test_deleteCollection() async throws {
        try await insertCollections(collections, userId: "1")

        try await subject.deleteCollection(id: "2", userId: "1")

        try XCTAssertEqual(
            fetchCollections(userId: "1"),
            collections.filter { $0.id != "2" }
        )
    }

    /// `fetchAllCollections(userId:)` fetches all collections for a user.
    func test_fetchAllCollections() async throws {
        try await insertCollections(collections, userId: "1")

        let fetchedCollections = try await subject.fetchAllCollections(userId: "1")
        XCTAssertEqual(fetchedCollections, collections)

        let emptyCollections = try await subject.fetchAllCollections(userId: "-1")
        XCTAssertEqual(emptyCollections, [])
    }

    /// `replaceCollections(_:userId)` replaces the list of collections for the user.
    func test_replaceCollections() async throws {
        try await insertCollections(collections, userId: "1")

        let newCollections = [
            Collection.fixture(id: "3", name: "COLLECTION3"),
            Collection.fixture(id: "4", name: "COLLECTION4"),
            Collection.fixture(id: "5", name: "COLLECTION5"),
        ]
        try await subject.replaceCollections(newCollections, userId: "1")

        XCTAssertEqual(try fetchCollections(userId: "1"), newCollections)
    }

    /// `upsertCollection(_:userId:)` inserts a collection for a user.
    func test_upsertCollection_insert() async throws {
        let collection = Collection.fixture(id: "1")
        try await subject.upsertCollection(collection, userId: "1")

        try XCTAssertEqual(fetchCollections(userId: "1"), [collection])

        let collection2 = Collection.fixture(id: "2")
        try await subject.upsertCollection(collection2, userId: "1")

        try XCTAssertEqual(fetchCollections(userId: "1"), [collection, collection2])
    }

    /// `upsertCollection(_:userId:)` updates an existing collection for a user.
    func test_upsertCollection_update() async throws {
        try await insertCollections(collections, userId: "1")

        let updatedCollection = Collection.fixture(id: "2", name: "UPDATED COLLECTION2")
        try await subject.upsertCollection(updatedCollection, userId: "1")

        var expectedCollections = collections
        expectedCollections[1] = updatedCollection

        try XCTAssertEqual(fetchCollections(userId: "1"), expectedCollections)
    }

    // MARK: Test Helpers

    /// A test helper to fetch all collection's for a user.
    private func fetchCollections(userId: String) throws -> [Collection] {
        let fetchRequest = CollectionData.fetchByUserIdRequest(userId: userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CollectionData.id, ascending: true)]
        return try subject.backgroundContext.fetch(fetchRequest).map(Collection.init)
    }

    /// A test helper for inserting a list of collections for a user.
    private func insertCollections(_ collections: [Collection], userId: String) async throws {
        try await subject.backgroundContext.performAndSave {
            for collection in collections {
                _ = try CollectionData(context: self.subject.backgroundContext, userId: userId, collection: collection)
            }
        }
    }
}
