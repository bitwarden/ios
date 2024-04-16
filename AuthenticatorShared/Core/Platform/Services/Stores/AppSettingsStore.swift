import Foundation
import OSLog

// MARK: - AppSettingsStore

/// A protocol for an object that persists app setting values.
///
protocol AppSettingsStore: AnyObject {
    /// The app's unique identifier.
    var appId: String? { get set }

    /// The app's locale.
    var appLocale: String? { get set }

    /// The app's theme.
    var appTheme: String? { get set }

    /// Whether to disable the website icons.
    var disableWebIcons: Bool { get set }

    /// Whether the user has seen the welcome tutorial.
    var hasSeenWelcomeTutorial: Bool { get set }

    /// The user ID for the local user
    var localUserId: String { get }

    /// The app's last data migration version.
    var migrationVersion: Int { get set }

    /// Gets the time after which the clipboard should be cleared.
    ///
    /// - Parameter userId: The user ID associated with the clipboard clearing time.
    ///
    /// - Returns: The time after which the clipboard should be cleared.
    ///
    func clearClipboardValue(userId: String) -> ClearClipboardValue

    /// Sets the time after which the clipboard should be cleared.
    ///
    /// - Parameters:
    ///   - clearClipboardValue: The time after which the clipboard should be cleared.
    ///   - userId: The user ID associated with the clipboard clearing time.
    ///
    /// - Returns: The time after which the clipboard should be cleared.
    ///
    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String)
}

// MARK: - DefaultAppSettingsStore

/// A default `AppSetingsStore` which persists app settings in `UserDefaults`.
///
class DefaultAppSettingsStore {
    // MARK: Properties

    let localUserId = "local"

    /// The `UserDefauls` instance to persist settings.
    let userDefaults: UserDefaults

    /// The bundleId used to set values that are bundleId dependent.
    var bundleId: String {
        Bundle.main.bundleIdentifier ?? Bundle.main.appIdentifier
    }

    // MARK: Initialization

    /// Initialize a `DefaultAppSettingsStore`.
    ///
    /// - Parameter userDefaults: The `UserDefaults` instance to persist settings.
    ///
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    // MARK: Private

    /// Fetches a `Bool` for the given key from `UserDefaults`.
    ///
    /// - Parameter key: The key used to store the value.
    /// - Returns: The value associated with the given key.
    ///
    private func fetch(for key: Keys) -> Bool {
        userDefaults.bool(forKey: key.storageKey)
    }

    /// Fetches a `Int` for the given key from `UserDefaults`.
    ///
    /// - Parameter key: The key used to store the value.
    /// - Returns: The value associated with the given key.
    ///
    private func fetch(for key: Keys) -> Int {
        userDefaults.integer(forKey: key.storageKey)
    }

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
        case appLocale
        case appTheme
        case clearClipboardValue(userId: String)
        case disableWebIcons
        case hasSeenWelcomeTutorial
        case migrationVersion

        /// Returns the key used to store the data under for retrieving it later.
        var storageKey: String {
            let key: String
            switch self {
            case .appId:
                key = "appId"
            case .appLocale:
                key = "appLocale"
            case .appTheme:
                key = "theme"
            case let .clearClipboardValue(userId):
                key = "clearClipboard_\(userId)"
            case .disableWebIcons:
                key = "disableFavicon"
            case .hasSeenWelcomeTutorial:
                key = "hasSeenWelcomeTutorial"
            case .migrationVersion:
                key = "migrationVersion"
            }
            return "bwaPreferencesStorage:\(key)"
        }
    }

    var appId: String? {
        get { fetch(for: .appId) }
        set { store(newValue, for: .appId) }
    }

    var appLocale: String? {
        get { fetch(for: .appLocale) }
        set { store(newValue, for: .appLocale) }
    }

    var appTheme: String? {
        get { fetch(for: .appTheme) }
        set { store(newValue, for: .appTheme) }
    }

    var disableWebIcons: Bool {
        get { fetch(for: .disableWebIcons) }
        set { store(newValue, for: .disableWebIcons) }
    }

    var hasSeenWelcomeTutorial: Bool {
        get { fetch(for: .hasSeenWelcomeTutorial) }
        set { store(newValue, for: .hasSeenWelcomeTutorial) }
    }

    func clearClipboardValue(userId: String) -> ClearClipboardValue {
        if let rawValue: Int = fetch(for: .clearClipboardValue(userId: userId)),
           let value = ClearClipboardValue(rawValue: rawValue) {
            return value
        }
        return .never
    }

    var migrationVersion: Int {
        get { fetch(for: .migrationVersion) }
        set { store(newValue, for: .migrationVersion) }
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String) {
        store(clearClipboardValue?.rawValue, for: .clearClipboardValue(userId: userId))
    }
}
