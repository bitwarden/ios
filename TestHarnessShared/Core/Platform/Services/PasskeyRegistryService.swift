import Foundation

// MARK: - PasskeyEntry

/// Metadata for a passkey registered via the Test Harness.
///
struct PasskeyEntry: Codable, Equatable, Identifiable {
    var id: UUID
    var rpId: String
    var userName: String
    var displayName: String
    var createdAt: Date
}

// MARK: - PasskeyRegistryService

/// A service that tracks passkeys registered through the Test Harness.
///
protocol PasskeyRegistryService {
    /// Saves a new passkey entry to the registry.
    func savePasskey(_ entry: PasskeyEntry)

    /// Returns all passkey entries stored in the registry.
    func loadPasskeys() -> [PasskeyEntry]

    /// Removes the specified entry from the registry.
    func deletePasskey(_ entry: PasskeyEntry)

    /// Removes all entries from the registry.
    func clearAll()
}

// MARK: - HasPasskeyRegistryService

protocol HasPasskeyRegistryService {
    var passkeyRegistryService: PasskeyRegistryService { get }
}

// MARK: - DefaultPasskeyRegistryService

/// Default implementation of `PasskeyRegistryService` backed by `UserDefaults`.
///
public class DefaultPasskeyRegistryService: PasskeyRegistryService {
    private static let storageKey = "com.bitwarden.testharness.registeredPasskeys"

    public init() {}

    func savePasskey(_ entry: PasskeyEntry) {
        var entries = loadPasskeys()
        entries.append(entry)
        persist(entries)
    }

    func loadPasskeys() -> [PasskeyEntry] {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PasskeyEntry].self, from: data)) ?? []
    }

    func deletePasskey(_ entry: PasskeyEntry) {
        persist(loadPasskeys().filter { $0.id != entry.id })
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    private func persist(_ entries: [PasskeyEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        UserDefaults.standard.set(try? encoder.encode(entries), forKey: Self.storageKey)
    }
}
