@testable import BitwardenShared

class MockCollectionService: CollectionService {
    var replaceCollectionsCollections: [CollectionDetailsResponseModel]?
    var replaceCollectionsUserId: String?

    func replaceCollections(_ collections: [CollectionDetailsResponseModel], userId: String) async throws {
        replaceCollectionsCollections = collections
        replaceCollectionsUserId = userId
    }
}
