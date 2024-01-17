import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockCollectionService: CollectionService {
    var collectionsSubject = CurrentValueSubject<[Collection], Error>([])

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

    func collectionsPublisher() async throws -> AnyPublisher<[Collection], Error> {
        collectionsSubject.eraseToAnyPublisher()
    }
}
