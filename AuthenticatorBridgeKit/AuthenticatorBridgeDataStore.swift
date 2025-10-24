import BitwardenKit
@preconcurrency import CoreData

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

/// The CoreData model name used within `AuthenticatorBridgeDataStore`.
private let authenticatorBridgeModelName = "Bitwarden-Authenticator"

/// A data store that manages persisting data across app launches in Core Data.
/// This is currently marked `@unchecked Sendable` because of how we ensure thread safety of the `backgroundContext`
/// property. Once we have a minimum version of iOS 16 or higher, we can migrate to the `Synchronization` framework
/// and make this more properly `Sendable`.
///
public final nonisolated class AuthenticatorBridgeDataStore: @unchecked Sendable {
    // MARK: Type Properties

    /// The managed object model representing the entities in the database schema. CoreData throws
    /// warnings if this is instantiated multiple times (e.g. in tests), which is fixed by making
    /// it static.
    private static let managedObjectModel: NSManagedObjectModel = {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: AuthenticatorBridgeDataStore.self)
        #endif

        let modelURL = bundle.url(forResource: authenticatorBridgeModelName, withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        return managedObjectModel
    }()

    // MARK: Properties

    /// A thread-safe lock for `backgroundContext`. Once we have a minimum of iOS 16, we can use an
    /// `OSAllocatedUnfairLock` instead.
    private let _backgroundContextLock = DispatchQueue(label: "backgroundContext.lock")

    /// A private backing for `backgroundContext`. The `backgroundContext` variable provides thread-safe access, and
    /// is what should be used. Once we have a minimum of iOS 16, this can be converted to an `OSAllocatedUnfairLock`,
    /// and remove the need for the additional `_backgroundContextLock`.
    private var _backgroundContext: NSManagedObjectContext?

    /// A managed object context which executes on a background queue.
    /// This is the thread-safe version of the backing variable `_backgroundContext`,
    /// and initializes that property lazily.
    public var backgroundContext: NSManagedObjectContext {
        _backgroundContextLock.sync {
            if let context = _backgroundContext {
                return context
            }
            let newContext = persistentContainer.newBackgroundContext()
            newContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            _backgroundContext = newContext
            return newContext
        }
    }

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

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
        storeType: AuthenticatorBridgeStoreType = .persisted,
    ) {
        self.errorReporter = errorReporter

        persistentContainer = NSPersistentContainer(
            name: authenticatorBridgeModelName,
            managedObjectModel: Self.managedObjectModel,
        )
        let storeDescription: NSPersistentStoreDescription
        switch storeType {
        case .memory:
            storeDescription = NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
        case .persisted:
            let storeURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)!
                .appendingPathComponent("\(authenticatorBridgeModelName).sqlite")
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
                additionalContexts: [self.persistentContainer.viewContext],
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
    public func executeBatchReplace(
        deleteRequest: NSBatchDeleteRequest,
        insertRequest: NSBatchInsertRequest,
    ) async throws {
        try await backgroundContext.perform {
            try self.backgroundContext.executeAndMergeChanges(
                batchDeleteRequest: deleteRequest,
                batchInsertRequest: insertRequest,
                additionalContexts: [self.persistentContainer.viewContext],
            )
        }
    }
}
