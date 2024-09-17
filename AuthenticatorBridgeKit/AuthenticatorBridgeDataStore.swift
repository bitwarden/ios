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

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The CoreData model name.
    private let modelName = "Bitwarden-Authenticator"

    /// The Core Data persistent container.
    public let persistentContainer: NSPersistentContainer

    // MARK: Initialization

    /// Initialize a `AuthenticatorBridgeDataStore`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - groupIdentifier: The app group identifier for the shared resource.
    ///   - storeType: The type of store to create.
    ///
    public init(
        errorReporter: ErrorReporter,
        groupIdentifier: String,
        storeType: AuthenticatorBridgeStoreType = .persisted
    ) {
        self.errorReporter = errorReporter

        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: type(of: self))
        #endif

        let modelURL = bundle.url(forResource: modelName, withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        persistentContainer = NSPersistentContainer(
            name: modelName,
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
                errorReporter.log(error: error)
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: Methods

    /// Executes a batch delete request and merges the changes into the background and view contexts.
    ///
    /// - Parameter request: The batch delete request to perform.
    ///
    public func executeBatchDelete(_ request: NSBatchDeleteRequest) async throws {
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
    public func executeBatchInsert(_ request: NSBatchInsertRequest) async throws {
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
    public func executeBatchReplace(
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
