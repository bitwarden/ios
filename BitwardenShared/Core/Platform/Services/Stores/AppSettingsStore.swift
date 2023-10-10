import Foundation
import OSLog

/// A protocol for an object that persists app setting values.
///
protocol AppSettingsStore: AnyObject {
    /// The app's unique identifier.
    var appId: String? { get set }

    /// The email being remembered on the landing screen.
    var rememberedEmail: String? { get set }

    /// The app's account state.
    var state: State? { get set }
}

// MARK: - DefaultAppSettingsStore

/// A default `AppSettingsStore` which persists app settings in `UserDefaults`.
///
class DefaultAppSettingsStore {
    // MARK: Properties

    /// The `UserDefaults` instance to persist settings.
    let userDefaults: UserDefaults

    // MARK: Initialization

    /// Initialize a `DefaultAppSettingsStore`.
    ///
    /// - Parameter userDefaults: The `UserDefaults` instance to persist settings.
    ///
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    // MARK: Private

    /// Fetches a `String` for the given key from `UserDefaults`.
    ///
    /// - Parameter key: The key used to store the value.
    /// - Returns: The value associated with the given key.
    ///
    private func fetch(for key: Keys) -> String? {
        userDefaults.string(forKey: key.storageKey)
    }

    /// Fetches and decodes a JSON encoded object for the given key from `UserDefaults`.
    ///
    /// - Parameters:
    ///   - key: The key used to store the value.
    ///   - decoder: The `JSONDecoder` used to decode JSON into the object type.
    /// - Returns: The value associated with the given key, decoded from JSON.
    ///
    private func fetch<T: Codable>(for key: Keys, decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let string = userDefaults.string(forKey: key.storageKey) else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: Data(string.utf8))
        } catch {
            Logger.application.error("Error fetching \(key.storageKey) from UserDefaults: \(error)")
            return nil
        }
    }

    /// Stores a `String` associated with the given key in `UserDefaults`.
    ///
    /// - Parameters:
    ///   - value: The value to store associated with the key.
    ///   - key: The key to associate with the value for retrieving it later.
    ///
    private func store(_ value: String?, for key: Keys) {
        userDefaults.set(value, forKey: key.storageKey)
    }

    /// Stores a JSON encoded object associated with the given key in `UserDefaults`.
    ///
    /// - Parameters:
    ///   - value: The value to store as JSON encoded data associated with the key.
    ///   - key:  The key to associate with the value for retrieving it later.
    ///   - encoder: The `JSONEncoder` used to encode the value as JSON.
    ///
    private func store<T: Codable>(_ value: T?, for key: Keys, encoder: JSONEncoder = JSONEncoder()) {
        guard let value else {
            userDefaults.removeObject(forKey: key.storageKey)
            return
        }

        do {
            let data = try encoder.encode(value)
            userDefaults.set(String(data: data, encoding: .utf8), forKey: key.storageKey)
        } catch {
            Logger.application.error(
                "Error storing \(key.storageKey): \(String(describing: value)) to UserDefaults: \(error)"
            )
        }
    }
}

extension DefaultAppSettingsStore: AppSettingsStore {
    /// The keys used to store their associated values.
    ///
    enum Keys: String, CaseIterable {
        case appId
        case rememberedEmail
        case state

        /// Returns the key used to store the data under for retrieving it later.
        var storageKey: String {
            "bwPreferencesStorage:\(rawValue)"
        }
    }

    var appId: String? {
        get { fetch(for: .appId) }
        set { store(newValue, for: .appId) }
    }

    var rememberedEmail: String? {
        get { fetch(for: .rememberedEmail) }
        set { store(newValue, for: .rememberedEmail) }
    }

    var state: State? {
        get { fetch(for: .state) }
        set { store(newValue, for: .state) }
    }
}
