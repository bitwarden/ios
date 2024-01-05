import BitwardenSdk

@testable import BitwardenShared

class MockCollectionService: CollectionService {
    var fetchAllCollectionsResult: Result<[Collection], Error> = .success([])
    var fetchAllCollectionsIncludeReadOnly: Bool?

    var replaceCollectionsCollections: [CollectionDetailsResponseModel]?
    var replaceCollectionsUserId: String?

    func fetchAllCollections(includeReadOnly: Bool) async throws -> [Collection] {
        fetchAllCollectionsIncludeReadOnly = includeReadOnly
        return try fetchAllCollectionsResult.get()
    }

    func replaceCollections(_ collections: [CollectionDetailsResponseModel], userId: String) async throws {
        replaceCollectionsCollections = collections
        replaceCollectionsUserId = userId
    }
}
