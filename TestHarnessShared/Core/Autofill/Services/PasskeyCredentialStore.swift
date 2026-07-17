import Foundation

// MARK: - PasskeyCredentialStore

/// A store for passkey credentials created during Test Harness registration flows, so they can
/// later be used to test the assertion/verification flow.
///
protocol PasskeyCredentialStore {
    /// Removes the previously saved passkey credential with the given identifier, if one exists.
    ///
    /// - Parameter id: The `StoredPasskeyCredential.id` of the credential to remove.
    ///
    func delete(id: String) throws

    /// Removes all previously saved passkey credentials.
    ///
    func deleteAll() throws

    /// Returns all previously saved passkey credentials, in the order they were created.
    func fetchAll() throws -> [StoredPasskeyCredential]

    /// Persists a newly created passkey credential, appending it to the existing list.
    ///
    /// - Parameter credential: The credential to persist.
    ///
    func save(_ credential: StoredPasskeyCredential) throws
}

// MARK: - DefaultPasskeyCredentialStore

/// A `UserDefaults`-backed implementation of `PasskeyCredentialStore`.
///
final class DefaultPasskeyCredentialStore: PasskeyCredentialStore {
    // MARK: Private Properties

    /// The key under which the encoded list of credentials is stored.
    private static let storageKey = "TestHarness:StoredPasskeyCredentials"

    /// The `UserDefaults` instance to persist credentials in.
    private let userDefaults: UserDefaults

    // MARK: Initialization

    /// Initializes a `DefaultPasskeyCredentialStore`.
    ///
    /// - Parameter userDefaults: The `UserDefaults` instance to persist credentials in.
    ///
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: Methods

    func delete(id: String) throws {
        let credentials = try fetchAll().filter { $0.id != id }
        try userDefaults.set(JSONEncoder().encode(credentials), forKey: Self.storageKey)
    }

    func deleteAll() throws {
        userDefaults.removeObject(forKey: Self.storageKey)
    }

    func fetchAll() throws -> [StoredPasskeyCredential] {
        guard let data = userDefaults.data(forKey: Self.storageKey) else { return [] }
        return try JSONDecoder().decode([StoredPasskeyCredential].self, from: data)
    }

    func save(_ credential: StoredPasskeyCredential) throws {
        var credentials = try fetchAll()
        credentials.append(credential)
        try userDefaults.set(JSONEncoder().encode(credentials), forKey: Self.storageKey)
    }
}
