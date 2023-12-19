import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockCollectionDataStore: CollectionDataStore {
    var deleteAllCollectionsUserId: String?

    var deleteCollectionId: String?
    var deleteCollectionUserId: String?

    var collectionSubject = CurrentValueSubject<[Collection], Error>([])

    var replaceCollectionsValue: [Collection]?
    var replaceCollectionsUserId: String?

    var upsertCollectionValue: Collection?
    var upsertCollectionUserId: String?

    func deleteAllCollections(userId: String) async throws {
        deleteAllCollectionsUserId = userId
    }

    func deleteCollection(id: String, userId: String) async throws {
        deleteCollectionId = id
        deleteCollectionUserId = userId
    }

    func collectionPublisher(userId: String) -> AnyPublisher<[Collection], Error> {
        collectionSubject.eraseToAnyPublisher()
    }

    func replaceCollections(_ collections: [Collection], userId: String) async throws {
        replaceCollectionsValue = collections
        replaceCollectionsUserId = userId
    }

    func upsertCollection(_ collection: Collection, userId: String) async throws {
        upsertCollectionValue = collection
        upsertCollectionUserId = userId
    }
}
