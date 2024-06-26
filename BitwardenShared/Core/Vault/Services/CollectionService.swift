import BitwardenSdk
import Combine

// MARK: - CollectionService

/// A protocol for a `CollectionService` which manages syncing and updates to the user's collections.
///
protocol CollectionService {
    /// Fetches the collections that are available to the user.
    ///
    /// - Parameter includeReadOnly: Whether to include read-only collections.
    /// - Returns: The collections that are available to the user.
    ///
    func fetchAllCollections(includeReadOnly: Bool) async throws -> [Collection]

    /// Replaces the persisted list of collections for the user.
    ///
    /// - Parameters:
    ///   - collections: The updated list of collections for the user.
    ///   - userId: The user ID associated with the collections.
    ///
    func replaceCollections(_ collections: [CollectionDetailsResponseModel], userId: String) async throws

    // MARK: Publishers

    /// A publisher for the list of collections.
    ///
    /// - Returns: The list of encrypted collections.
    ///
    func collectionsPublisher() async throws -> AnyPublisher<[Collection], Error>
}

// MARK: - DefaultCollectionService

class DefaultCollectionService: CollectionService {
    // MARK: Properties

    /// The data store for managing the persisted collections for the user.
    private let collectionDataStore: CollectionDataStore

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultCollectionService`.
    ///
    /// - Parameters:
    ///   - collectionDataStore: The data store for managing the persisted collections for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(collectionDataStore: CollectionDataStore, stateService: StateService) {
        self.collectionDataStore = collectionDataStore
        self.stateService = stateService
    }
}

extension DefaultCollectionService {
    func fetchAllCollections(includeReadOnly: Bool) async throws -> [Collection] {
        let userId = try await stateService.getActiveAccountId()
        return try await collectionDataStore.fetchAllCollections(userId: userId)
            .filter { includeReadOnly ? true : !$0.readOnly }
    }

    func replaceCollections(_ collections: [CollectionDetailsResponseModel], userId: String) async throws {
        try await collectionDataStore.replaceCollections(collections.map(Collection.init), userId: userId)
    }

    func collectionsPublisher() async throws -> AnyPublisher<[Collection], Error> {
        let userId = try await stateService.getActiveAccountId()
        return collectionDataStore.collectionPublisher(userId: userId)
    }
}
