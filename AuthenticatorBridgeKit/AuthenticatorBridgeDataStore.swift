import CoreData

// MARK: - AuthenticatorStoreType

/// A type of data store.
///
public enum AuthenticatorBridgeStoreType {
    /// The data store is stored only in memory and isn't persisted to the device. This is used for
    /// unit testing.
    case memory

    /// The data store is persisted to the device.
    case persisted
}

// MARK: - AuthenticatorDataStore

/// A data store that manages persisting data across app launches in Core Data.
///
public class AuthenticatorBridgeDataStore {
    // MARK: Properties

    /// A managed object context which executes on a background queue.
    private(set) lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()

    /// The Core Data persistent container.
    public let persistentContainer: NSPersistentContainer

    // MARK: Initialization

    /// Initialize a `AuthenticatorBridgeDataStore`.
    ///
    /// - Parameters:
    ///   - storeType: The type of store to create.
    ///   - appGroupIdentifier: The app group identifier for the shared resource.
    ///   - errorHandler: Callback if an error occurs on load of store.
    ///
    public init(
        storeType: AuthenticatorBridgeStoreType = .persisted,
        groupIdentifier: String,
        errorHandler: @escaping (Error) -> Void
    ) {
        #if SWIFT_PACKAGE
        let modelURL = Bundle.module.url(forResource: "Bitwarden-Authenticator", withExtension: "momd")!
        #else
        let modelURL = Bundle(for: type(of: self)).url(forResource: "Bitwarden-Authenticator", withExtension: "momd")!
        #endif

        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        persistentContainer = NSPersistentContainer(
            name: "Bitwarden-Authenticator",
            managedObjectModel: managedObjectModel
        )
        let storeDescription: NSPersistentStoreDescription
        switch storeType {
        case .memory:
            storeDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
        case .persisted:
            let storeURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)!
                .appendingPathComponent("Bitwarden-Authenticator.sqlite")
            storeDescription = NSPersistentStoreDescription(url: storeURL)
        }
        persistentContainer.persistentStoreDescriptions = [storeDescription]

        persistentContainer.loadPersistentStores { _, error in
            if let error {
                errorHandler(error)
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: Methods

    /// Removes all items that are owned by the specific userId
    ///
    /// - Parameter userId: the id of the user for which to delete all items.
    ///
    public func deleteAllForUserId(_ userId: String) async throws {
        try await executeBatchDelete(AuthenticatorBridgeItemData.deleteByUserIdRequest(userId: userId))
    }

    /// Fetches all items that are owned by the specific userId
    ///
    /// - Parameter userId: the id of the user for which to fetch items.
    ///
    public func fetchAllForUserId(_ userId: String) async throws -> [AuthenticatorBridgeItemDataModel] {
        let fetchRequest = AuthenticatorBridgeItemData.fetchByUserIdRequest(userId: userId)
        let result = try persistentContainer.viewContext.fetch(fetchRequest)

        return try result.map { data in
            try data.model
        }
    }

    /// Inserts the list of items into the store for the given userId.
    ///
    /// - Parameters:
    ///   - items: The list of `AuthenticatorBridgeItemDataModel` to be inserted into the store.
    ///   - userId: the id of the user for which to insert the items.
    ///
    public func insertItems(_ items: [AuthenticatorBridgeItemDataModel],
                            forUserId userId: String) async throws {
        try await executeBatchInsert(
            AuthenticatorBridgeItemData.batchInsertRequest(models: items, userId: userId)
        )
    }

    /// Deletes all existing items for a given user and inserts new items for the list of items provided.
    ///
    /// - Parameters:
    ///   - items: The new items to be inserted into the store
    ///   - userId: The userId of the items to be removed and then replaces with items.
    ///
    public func replaceAllItems(with items: [AuthenticatorBridgeItemDataModel],
                                forUserId userId: String) async throws {
        let deleteRequest = AuthenticatorBridgeItemData.deleteByUserIdRequest(userId: userId)
        let insertRequest = try AuthenticatorBridgeItemData.batchInsertRequest(models: items, userId: userId)
        try await executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest
        )
    }

    /// Executes a batch delete request and merges the changes into the background and view contexts.
    ///
    /// - Parameter request: The batch delete request to perform.
    ///
    private func executeBatchDelete(_ request: NSBatchDeleteRequest) async throws {
        try await backgroundContext.perform {
            try self.backgroundContext.executeAndMergeChanges(
                batchDeleteRequest: request,
                additionalContexts: [self.persistentContainer.viewContext]
            )
        }
    }

    /// Executes a batch insert request and merges the changes into the background and view contexts.
    ///
    /// - Parameter request: The batch insert request to perform.
    ///
    private func executeBatchInsert(_ request: NSBatchInsertRequest) async throws {
        try await backgroundContext.perform {
            try self.backgroundContext.executeAndMergeChanges(
                batchInsertRequest: request,
                additionalContexts: [self.persistentContainer.viewContext]
            )
        }
    }

    /// Executes a batch delete and batch insert request and merges the changes into the background
    /// and view contexts.
    ///
    /// - Parameters:
    ///   - deleteRequest: The batch delete request to perform.
    ///   - insertRequest: The batch insert request to perform.
    ///
    private func executeBatchReplace(
        deleteRequest: NSBatchDeleteRequest,
        insertRequest: NSBatchInsertRequest
    ) async throws {
        try await backgroundContext.perform {
            try self.backgroundContext.executeAndMergeChanges(
                batchDeleteRequest: deleteRequest,
                batchInsertRequest: insertRequest,
                additionalContexts: [self.persistentContainer.viewContext]
            )
        }
    }
}
