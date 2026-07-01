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
    func savePasskey(_ entry: PasskeyEntry) async

    /// Returns all passkey entries stored in the registry.
    func loadPasskeys() async -> [PasskeyEntry]

    /// Removes the specified entry from the registry.
    func deletePasskey(_ entry: PasskeyEntry) async

    /// Removes all entries from the registry.
    func clearAll() async
}

// MARK: - HasPasskeyRegistryService

protocol HasPasskeyRegistryService {
    var passkeyRegistryService: PasskeyRegistryService { get }
}

// MARK: - DefaultPasskeyRegistryService

/// Passkey registry backed by `UserDefaults`.
///
class DefaultPasskeyRegistryService: PasskeyRegistryService {
    // MARK: Private Properties

    private let defaults: UserDefaults
    private let storageKey = "passkeyRegistry"

    private let decoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        return jsonDecoder
    }()

    private let encoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        return jsonEncoder
    }()

    // MARK: Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: PasskeyRegistryService

    func savePasskey(_ entry: PasskeyEntry) async {
        var entries = await loadPasskeys()
        entries.append(entry)
        persist(entries)
    }

    func loadPasskeys() async -> [PasskeyEntry] {
        guard
            let data = defaults.data(forKey: storageKey),
            let entries = try? decoder.decode([PasskeyEntry].self, from: data)
        else { return [] }
        return entries
    }

    func deletePasskey(_ entry: PasskeyEntry) async {
        var entries = await loadPasskeys()
        entries.removeAll { $0.id == entry.id }
        persist(entries)
    }

    func clearAll() async {
        defaults.removeObject(forKey: storageKey)
    }

    // MARK: Private

    private func persist(_ entries: [PasskeyEntry]) {
        guard let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
