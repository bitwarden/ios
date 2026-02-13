import BitwardenKit
import CryptoKit
import Foundation
import OSLog

// MARK: - AppSettingsStore

// swiftlint:disable file_length

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

    /// The default save location for new keys.
    var defaultSaveOption: DefaultSaveOption { get set }

    /// The data used by the flight recorder for the active and any inactive logs.
    var flightRecorderData: FlightRecorderData? { get set }

    /// Whether the user has seen the default save options prompt.
    var hasSeenDefaultSaveOptionPrompt: Bool { get }

    /// Whether the user has seen the welcome tutorial.
    var hasSeenWelcomeTutorial: Bool { get set }

    /// The user ID for the local user
    var localUserId: String { get }

    /// The app's last data migration version.
    var migrationVersion: Int { get set }

    /// The server config used prior to user authentication.
    var preAuthServerConfig: ServerConfig? { get set }

    /// Gets the closed state for the given card.
    ///
    /// - Parameter card: The card to get the closed state for.
    ///
    /// - Returns: Whether or not this card has been closed.
    ///
    func cardClosedState(card: ItemListCard) -> Bool

    /// Gets the time after which the clipboard should be cleared.
    ///
    /// - Parameter userId: The user ID associated with the clipboard clearing time.
    ///
    /// - Returns: The time after which the clipboard should be cleared.
    ///
    func clearClipboardValue(userId: String) -> ClearClipboardValue

    /// Flag to identify if the user has previously synced with the named account. `true` if they have previously
    /// synced with the named account, `false` if they have not synced previously.
    ///
    /// - Parameter name: The name of the account that the user has/hasn't synced with previously.
    ///
    /// - Returns: A `Bool` indicating if the user has synced with the named account previously.
    ///     If `true`, the user has already synced with the named account.
    ///     If `false`, the user has not synced with the named account.
    ///
    func hasSyncedAccount(name: String) -> Bool

    /// Get the user's Biometric Authentication Preference.
    ///
    /// - Parameter userId: The user ID associated with the biometric authentication preference.
    ///
    /// - Returns: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///
    func isBiometricAuthenticationEnabled(userId: String) -> Bool

    /// The user's last active time within the app.
    /// This value is set when the app is backgrounded.
    ///
    /// - Parameter userId: The user ID associated with the last active time within the app.
    ///
    func lastActiveTime(userId: String) -> Date?

    /// Gets the user's secret encryption key.
    ///
    /// - Parameters:
    ///   - userId: The user ID
    ///
    func secretKey(userId: String) -> String?

    /// The server configuration.
    ///
    /// - Parameter userId: The user ID associated with the server config.
    /// - Returns: The server config for that user ID.
    func serverConfig(userId: String) -> ServerConfig?

    /// Sets the user's Biometric Authentication Preference.
    ///
    /// - Parameters:
    ///   - isEnabled: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///   - userId: The user ID associated with the biometric authentication preference.
    ///
    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?, for userId: String)

    /// Sets the closed state to true for the given card.
    ///
    /// - Parameter card: The card to set the closed state for.
    ///
    func setCardClosedState(card: ItemListCard)

    /// Sets the time after which the clipboard should be cleared.
    ///
    /// - Parameters:
    ///   - clearClipboardValue: The time after which the clipboard should be cleared.
    ///   - userId: The user ID associated with the clipboard clearing time.
    ///
    /// - Returns: The time after which the clipboard should be cleared.
    ///
    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String)

    /// Sets the flag to `true` to identify the user has previously synced with the named account.
    ///
    /// - Parameters:
    ///   - name: The name of the account that the user has synced with previously.
    ///
    func setHasSyncedAccount(name: String)

    /// Sets the last active time within the app.
    ///
    /// - Parameters:
    ///   - date: The current time.
    ///   - userId: The user ID associated with the last active time within the app.
    ///
    func setLastActiveTime(_ date: Date?, userId: String)

    /// Sets the user's secret encryption key.
    ///
    /// - Parameters:
    ///   - key: The key to set
    ///   - userId: The user ID
    ///
    func setSecretKey(_ key: String, userId: String)

    /// Sets the server config.
    ///
    /// - Parameters:
    ///   - config: The server config for the user
    ///   - userId: The user ID.
    ///
    func setServerConfig(_ config: ServerConfig?, userId: String)

    /// Sets the user's session timeout, in minutes.
    ///
    /// - Parameters:
    ///   - key: The session timeout, in minutes.
    ///   - userId: The user ID associated with the session timeout.
    ///
    func setVaultTimeout(minutes: Int, userId: String)

    /// Returns the session timeout in minutes.
    ///
    /// - Parameter userId: The user ID associated with the session timeout.
    /// - Returns: The user's session timeout in minutes.
    ///
    func vaultTimeout(userId: String) -> Int?
}

// MARK: - DefaultAppSettingsStore

/// A default `AppSettingsStore` which persists app settings in `UserDefaults`.
///
class DefaultAppSettingsStore {
    // MARK: Properties

    let localUserId = "local"

    /// The `UserDefaults` instance to persist settings.
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
                "Error storing \(key.storageKey): \(String(describing: value)) to UserDefaults: \(error)",
            )
        }
    }
}

extension DefaultAppSettingsStore: AppSettingsStore, ConfigSettingsStore {
    /// The keys used to store their associated values.
    ///
    enum Keys {
        case appId
        case appLocale
        case appTheme
        case biometricAuthEnabled(userId: String)
        case cardClosedState(card: ItemListCard)
        case clearClipboardValue(userId: String)
        case debugFeatureFlag(name: String)
        case defaultSaveOption
        case disableWebIcons
        case flightRecorderData
        case hasSeenWelcomeTutorial
        case hasSyncedAccount(name: String)
        case lastActiveTime(userId: String)
        case migrationVersion
        case preAuthServerConfig
        case secretKey(userId: String)
        case serverConfig(userId: String)
        case vaultTimeout(userId: String)

        /// Returns the key used to store the data under for retrieving it later.
        var storageKey: String {
            let key = switch self {
            case .appId:
                "appId"
            case .appLocale:
                "appLocale"
            case .appTheme:
                "theme"
            case let .biometricAuthEnabled(userId):
                "biometricUnlock_\(userId)"
            case let .cardClosedState(card: card):
                "cardClosedState_\(card)"
            case let .clearClipboardValue(userId):
                "clearClipboard_\(userId)"
            case let .debugFeatureFlag(name):
                "debugFeatureFlag_\(name)"
            case .defaultSaveOption:
                "defaultSaveOption"
            case .disableWebIcons:
                "disableFavicon"
            case .flightRecorderData:
                "flightRecorderData"
            case .hasSeenWelcomeTutorial:
                "hasSeenWelcomeTutorial"
            case let .hasSyncedAccount(name: name):
                "hasSyncedAccount_\(name)"
            case let .lastActiveTime(userId):
                "lastActiveTime_\(userId)"
            case .migrationVersion:
                "migrationVersion"
            case .preAuthServerConfig:
                "preAuthServerConfig"
            case let .secretKey(userId):
                "secretKey_\(userId)"
            case let .serverConfig(userId):
                "serverConfig_\(userId)"
            case let .vaultTimeout(userId):
                "vaultTimeout_\(userId)"
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

    var defaultSaveOption: DefaultSaveOption {
        get {
            guard let rawValue: String = fetch(for: .defaultSaveOption),
                  let value = DefaultSaveOption(rawValue: rawValue)
            else { return .none }

            return value
        }
        set { store(newValue.rawValue, for: .defaultSaveOption) }
    }

    var flightRecorderData: FlightRecorderData? {
        get { fetch(for: .flightRecorderData) }
        set { store(newValue, for: .flightRecorderData) }
    }

    var hasSeenDefaultSaveOptionPrompt: Bool {
        fetch(for: .defaultSaveOption) != nil
    }

    var hasSeenWelcomeTutorial: Bool {
        get { fetch(for: .hasSeenWelcomeTutorial) }
        set { store(newValue, for: .hasSeenWelcomeTutorial) }
    }

    var migrationVersion: Int {
        get { fetch(for: .migrationVersion) }
        set { store(newValue, for: .migrationVersion) }
    }

    var preAuthServerConfig: ServerConfig? {
        get { fetch(for: .preAuthServerConfig) }
        set { store(newValue, for: .preAuthServerConfig) }
    }

    func cardClosedState(card: ItemListCard) -> Bool {
        fetch(for: .cardClosedState(card: card))
    }

    func clearClipboardValue(userId: String) -> ClearClipboardValue {
        if let rawValue: Int = fetch(for: .clearClipboardValue(userId: userId)),
           let value = ClearClipboardValue(rawValue: rawValue) {
            return value
        }
        return .never
    }

    func debugFeatureFlag(name: String) -> Bool? {
        fetch(for: .debugFeatureFlag(name: name))
    }

    func hasSyncedAccount(name: String) -> Bool {
        fetch(for: .hasSyncedAccount(name: name.hexSHA256Hash))
    }

    func isBiometricAuthenticationEnabled(userId: String) -> Bool {
        fetch(for: .biometricAuthEnabled(userId: userId))
    }

    func lastActiveTime(userId: String) -> Date? {
        fetch(for: .lastActiveTime(userId: userId)).map { Date(timeIntervalSince1970: $0) }
    }

    func overrideDebugFeatureFlag(name: String, value: Bool?) {
        store(value, for: .debugFeatureFlag(name: name))
    }

    func secretKey(userId: String) -> String? {
        fetch(for: .secretKey(userId: userId))
    }

    func serverConfig(userId: String) -> ServerConfig? {
        fetch(for: .serverConfig(userId: userId))
    }

    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?, for userId: String) {
        store(isEnabled, for: .biometricAuthEnabled(userId: userId))
    }

    func setCardClosedState(card: ItemListCard) {
        store(true, for: .cardClosedState(card: card))
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String) {
        store(clearClipboardValue?.rawValue, for: .clearClipboardValue(userId: userId))
    }

    func setHasSyncedAccount(name: String) {
        store(true, for: .hasSyncedAccount(name: name.hexSHA256Hash))
    }

    func setLastActiveTime(_ date: Date?, userId: String) {
        store(date?.timeIntervalSince1970, for: .lastActiveTime(userId: userId))
    }

    func setSecretKey(_ key: String, userId: String) {
        store(key, for: .secretKey(userId: userId))
    }

    func setServerConfig(_ config: ServerConfig?, userId: String) {
        store(config, for: .serverConfig(userId: userId))
    }

    func setVaultTimeout(minutes: Int, userId: String) {
        store(minutes, for: .vaultTimeout(userId: userId))
    }

    func vaultTimeout(userId: String) -> Int? {
        fetch(for: .vaultTimeout(userId: userId))
    }
}

/// An enumeration of possible item list cards.
///
enum ItemListCard: String {
    /// The password manager download card.
    case passwordManagerDownload

    /// The password manager sync card.
    case passwordManagerSync
}
