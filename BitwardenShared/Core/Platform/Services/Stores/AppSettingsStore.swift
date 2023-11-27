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

    /// Gets the encrypted private key for the user ID.
    ///
    /// - Parameter userId: The user ID associated with the encrypted private key.
    ///
    func encryptedPrivateKey(userId: String) -> String?

    /// Gets the encrypted user key for the user ID.
    ///
    /// - Parameter userId: The user ID associated with the encrypted user key.
    ///
    func encryptedUserKey(userId: String) -> String?

    /// Gets the password generation options for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the password generation options.
    /// - Returns: The password generation options for the user ID.
    ///
    func passwordGenerationOptions(userId: String) -> PasswordGenerationOptions?

    /// Gets the username generation options for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the username generation options.
    /// - Returns: The username generation options for the user ID.
    ///
    func usernameGenerationOptions(userId: String) -> UsernameGenerationOptions?

    /// Sets the encrypted private key for a user ID.
    ///
    /// - Parameters:
    ///   - key: The user's encrypted private key.
    ///   - userId: The user ID associated with the encrypted private key.
    ///
    func setEncryptedPrivateKey(key: String?, userId: String)

    /// Sets the encrypted user key for a user ID.
    ///
    /// - Parameters:
    ///   - key: The user's encrypted user key.
    ///   - userId: The user ID associated with the encrypted user key.
    ///
    func setEncryptedUserKey(key: String?, userId: String)

    /// Sets the password generation options for a user ID.
    ///
    /// - Parameters:
    ///   - options: The user's password generation options.
    ///   - userId: The user ID associated with the password generation options.
    ///
    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String)

    /// Sets the username generation options for a user ID.
    ///
    /// - Parameters:
    ///   - options: The user's username generation options.
    ///   - userId: The user ID associated with the username generation options.
    ///
    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String)
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
    enum Keys {
        case appId
        case encryptedPrivateKey(userId: String)
        case encryptedUserKey(userId: String)
        case passwordGenerationOptions(userId: String)
        case rememberedEmail
        case state
        case usernameGenerationOptions(userId: String)

        /// Returns the key used to store the data under for retrieving it later.
        var storageKey: String {
            let key: String
            switch self {
            case .appId:
                key = "appId"
            case let .encryptedUserKey(userId):
                key = "masterKeyEncryptedUserKey_\(userId)"
            case let .encryptedPrivateKey(userId):
                key = "encPrivateKey_\(userId)"
            case let .passwordGenerationOptions(userId):
                key = "passwordGenerationOptions_\(userId)"
            case .rememberedEmail:
                key = "rememberedEmail"
            case .state:
                key = "state"
            case let .usernameGenerationOptions(userId):
                key = "usernameGenerationOptions_\(userId)"
            }
            return "bwPreferencesStorage:\(key)"
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

    func encryptedPrivateKey(userId: String) -> String? {
        fetch(for: .encryptedPrivateKey(userId: userId))
    }

    func encryptedUserKey(userId: String) -> String? {
        fetch(for: .encryptedUserKey(userId: userId))
    }

    func passwordGenerationOptions(userId: String) -> PasswordGenerationOptions? {
        fetch(for: .passwordGenerationOptions(userId: userId))
    }

    func usernameGenerationOptions(userId: String) -> UsernameGenerationOptions? {
        fetch(for: .usernameGenerationOptions(userId: userId))
    }

    func setEncryptedPrivateKey(key: String?, userId: String) {
        store(key, for: .encryptedPrivateKey(userId: userId))
    }

    func setEncryptedUserKey(key: String?, userId: String) {
        store(key, for: .encryptedUserKey(userId: userId))
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String) {
        store(options, for: .passwordGenerationOptions(userId: userId))
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String) {
        store(options, for: .usernameGenerationOptions(userId: userId))
    }
}
