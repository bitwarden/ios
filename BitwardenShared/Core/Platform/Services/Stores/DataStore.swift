import BitwardenKit
import BitwardenSdk
import Combine
import CoreData

// MARK: - StoreType

/// A type of data store.
///
enum StoreType {
    /// The data store is stored only in memory and isn't persisted to the device. This is used for
    /// unit testing.
    case memory

    /// The data store is persisted to the device.
    case persisted
}

// MARK: - DataStore

/// A data store that manages persisting data across app launches in Core Data.
///
class DataStore {
    // MARK: Type Properties

    /// The managed object model representing the entities in the database schema. CoreData throws
    /// warnings if this is instantiated multiple times (e.g. in tests), which is fixed by making
    /// it static.
    private static let managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle(for: DataStore.self).url(forResource: "Bitwarden", withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        return managedObjectModel
    }()

    // MARK: Properties

    /// A managed object context which executes on a background queue.
    private(set) lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()

    /// A subject that emits cipher changes for all users.
    let cipherChangeSubject = PassthroughSubject<(userId: String, change: CipherChange), Error>()

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The Core Data persistent container.
    let persistentContainer: NSPersistentContainer

    // MARK: Initialization

    /// Initialize a `DataStore`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - storeType: The type of store to create.
    ///
    init(errorReporter: ErrorReporter, storeType: StoreType = .persisted) {
        self.errorReporter = errorReporter

        persistentContainer = NSPersistentContainer(name: "Bitwarden", managedObjectModel: Self.managedObjectModel)
        let storeDescription: NSPersistentStoreDescription
        switch storeType {
        case .memory:
            storeDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
        case .persisted:
            let storeURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Bundle.main.groupIdentifier)!
                .appendingPathComponent("Bitwarden.sqlite")
            storeDescription = NSPersistentStoreDescription(url: storeURL)
        }
        persistentContainer.persistentStoreDescriptions = [storeDescription]
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                errorReporter.log(error: error)
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: Methods

    /// Deletes all data stored in the store for a specified user.
    ///
    /// - Parameter userId: The ID of the user associated with the data to delete.
    ///
    func deleteDataForUser(userId: String) async throws {
        try await backgroundContext.perform {
            // Batch delete all data and perform a single merge of those changes back into the
            // view context.
            try self.backgroundContext.executeAndMergeChanges(
                batchDeleteRequests: [
                    CipherData.deleteByUserIdRequest(userId: userId),
                    CollectionData.deleteByUserIdRequest(userId: userId),
                    FolderData.deleteByUserIdRequest(userId: userId),
                    OrganizationData.deleteByUserIdRequest(userId: userId),
                    PasswordHistoryData.deleteByUserIdRequest(userId: userId),
                    PolicyData.deleteByUserIdRequest(userId: userId),
                    SendData.deleteByUserIdRequest(userId: userId),
                    DomainData.deleteByUserIdRequest(userId: userId),
                ],
            )
        }
    }

    /// Executes a batch delete request and merges the changes into the background and view contexts.
    ///
    /// - Parameter request: The batch delete request to perform.
    ///
    func executeBatchDelete(_ request: NSBatchDeleteRequest) async throws {
        try await executeBatchDelete([request])
    }

    /// Executes multiple batch delete requests and merges the changes into the background and view contexts.
    ///
    /// - Parameter requests: The batch delete requests to perform.
    ///
    func executeBatchDelete(_ requests: [NSBatchDeleteRequest]) async throws {
        try await backgroundContext.perform {
            try self.backgroundContext.executeAndMergeChanges(
                batchDeleteRequests: requests,
                additionalContexts: [self.persistentContainer.viewContext],
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
    func executeBatchReplace(deleteRequest: NSBatchDeleteRequest, insertRequest: NSBatchInsertRequest) async throws {
        try await backgroundContext.perform {
            try self.backgroundContext.executeAndMergeChanges(
                batchDeleteRequest: deleteRequest,
                batchInsertRequest: insertRequest,
                additionalContexts: [self.persistentContainer.viewContext],
            )
        }
    }
}
