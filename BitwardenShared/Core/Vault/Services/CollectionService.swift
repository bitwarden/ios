import BitwardenSdk

// MARK: - CollectionService

/// A protocol for a `CollectionService` which manages syncing and updates to the user's collections.
///
protocol CollectionService {
    /// Replaces the persisted list of collections for the user.
    ///
    /// - Parameters:
    ///   - collections: The updated list of collections for the user.
    ///   - userId: The user ID associated with the collections.
    ///
    func replaceCollections(_ collections: [CollectionDetailsResponseModel], userId: String) async throws
}

// MARK: - DefaultCollectionService

class DefaultCollectionService: CollectionService {
    // MARK: Properties

    /// The data store for managing the persisted collections for the user.
    let collectionDataStore: CollectionDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

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
    func replaceCollections(_ collections: [CollectionDetailsResponseModel], userId: String) async throws {
        try await collectionDataStore.replaceCollections(collections.map(Collection.init), userId: userId)
    }
}
