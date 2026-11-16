#if DEBUG
import BitwardenKit
import BitwardenKitMocks
import CoreData
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - DebugAppStateResetterTests

@Suite(.serialized)
final class DebugAppStateResetterTests {
    // MARK: Properties

    let appGroupUserDefaults: UserDefaults
    let directory: URL
    let keychainService: MockKeychainService
    let standardUserDefaults: UserDefaults
    let subject: DebugAppStateResetter

    /// A scratch directory holding the data store and the app's files.
    let scratchDirectory: URL

    var dataStoreURL: URL { scratchDirectory.appendingPathComponent("Store.sqlite") }

    // MARK: Initialization

    init() throws {
        appGroupUserDefaults = try #require(UserDefaults(suiteName: "DebugAppStateResetterTests.appGroup"))
        standardUserDefaults = try #require(UserDefaults(suiteName: "DebugAppStateResetterTests.standard"))
        keychainService = MockKeychainService()

        scratchDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        directory = scratchDirectory.appendingPathComponent("Files", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        subject = DebugAppStateResetter(
            appGroupUserDefaults: appGroupUserDefaults,
            dataStoreURL: scratchDirectory.appendingPathComponent("Store.sqlite"),
            directories: [directory, scratchDirectory.appendingPathComponent("Missing")],
            keychainService: keychainService,
            standardUserDefaults: standardUserDefaults,
        )
    }

    deinit {
        appGroupUserDefaults.removePersistentDomain(forName: "DebugAppStateResetterTests.appGroup")
        standardUserDefaults.removePersistentDomain(forName: "DebugAppStateResetterTests.standard")
        try? FileManager.default.removeItem(at: scratchDirectory)
    }

    // MARK: Tests

    /// `resetIfRequested()` erases the settings, the data store, the keychain, cookies and files.
    @Test
    func resetIfRequested_erasesAllState() throws {
        standardUserDefaults.set(true, forKey: Constants.DebugLaunchArguments.resetAppState)
        standardUserDefaults.set("value", forKey: "standardValue")
        appGroupUserDefaults.set("value", forKey: "bwPreferencesStorage:state")
        appGroupUserDefaults.set(5, forKey: "bwPreferencesStorage:migrationVersion")
        try Data("log".utf8).write(to: directory.appendingPathComponent("cached.txt"))
        try insertObject()
        #expect(try objectCount() == 1)
        var deletedQueries = [CFDictionary]()
        keychainService.deleteClosure = { deletedQueries.append($0) }
        let cookie = try #require(HTTPCookie(properties: [
            .domain: "reset.example.com",
            .name: "sso",
            .path: "/",
            .value: "value",
        ]))
        HTTPCookieStorage.shared.setCookie(cookie)

        let errors = subject.resetIfRequested()

        #expect(errors.isEmpty)
        #expect(appGroupUserDefaults.object(forKey: "bwPreferencesStorage:state") == nil)
        #expect(appGroupUserDefaults.object(forKey: "bwPreferencesStorage:migrationVersion") == nil)
        #expect(standardUserDefaults.object(forKey: "standardValue") == nil)
        #expect(try objectCount() == 0)
        #expect(deletedQueries == [
            [kSecClass: kSecClassGenericPassword] as CFDictionary,
            [kSecClass: kSecClassInternetPassword] as CFDictionary,
            [kSecClass: kSecClassCertificate] as CFDictionary,
            [kSecClass: kSecClassKey] as CFDictionary,
            [kSecClass: kSecClassIdentity] as CFDictionary,
        ])
        #expect(HTTPCookieStorage.shared.cookies?.contains { $0.domain == "reset.example.com" } == false)
        #expect(FileManager.default.fileExists(atPath: directory.path))
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
    }

    /// `resetIfRequested()` returns the error of a step that fails and still runs the others.
    @Test
    func resetIfRequested_error_continues() throws {
        standardUserDefaults.set(true, forKey: Constants.DebugLaunchArguments.resetAppState)
        appGroupUserDefaults.set("value", forKey: "bwPreferencesStorage:state")
        try Data("log".utf8).write(to: directory.appendingPathComponent("cached.txt"))
        keychainService.deleteThrowableError = KeychainServiceError.osStatusError(errSecParam)

        let errors = subject.resetIfRequested()

        #expect(errors.count == 5)
        #expect(appGroupUserDefaults.object(forKey: "bwPreferencesStorage:state") == nil)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
    }

    /// `resetIfRequested()` does nothing if the launch argument isn't set.
    @Test
    func resetIfRequested_noArgument_keepsState() throws {
        standardUserDefaults.set("value", forKey: "standardValue")
        appGroupUserDefaults.set("value", forKey: "bwPreferencesStorage:state")
        try Data("log".utf8).write(to: directory.appendingPathComponent("cached.txt"))
        try insertObject()

        let errors = subject.resetIfRequested()

        #expect(errors.isEmpty)
        #expect(standardUserDefaults.string(forKey: "standardValue") == "value")
        #expect(appGroupUserDefaults.string(forKey: "bwPreferencesStorage:state") == "value")
        #expect(try objectCount() == 1)
        #expect(keychainService.deleteCalled == false)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path) == ["cached.txt"])
    }

    // MARK: Private

    /// Inserts one object into the SQLite store at `dataStoreURL`.
    ///
    private func insertObject() throws {
        let container = try makeContainer()
        NSEntityDescription.insertNewObject(forEntityName: "Item", into: container.viewContext)
        try container.viewContext.save()
        try closeStores(of: container)
    }

    /// Returns the number of objects in the SQLite store at `dataStoreURL`.
    ///
    private func objectCount() throws -> Int {
        let container = try makeContainer()
        let count = try container.viewContext.count(for: NSFetchRequest<NSManagedObject>(entityName: "Item"))
        try closeStores(of: container)
        return count
    }

    private func closeStores(of container: NSPersistentContainer) throws {
        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
    }

    private func makeContainer() throws -> NSPersistentContainer {
        let entity = NSEntityDescription()
        entity.name = "Item"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        let model = NSManagedObjectModel()
        model.entities = [entity]

        let container = NSPersistentContainer(name: "Store", managedObjectModel: model)
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: dataStoreURL)]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        return container
    }
}
#endif
