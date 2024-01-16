import Combine
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

    /// The environment URLs used prior to user authentication.
    var preAuthEnvironmentUrls: EnvironmentUrlData? { get set }

    /// The email being remembered on the landing screen.
    var rememberedEmail: String? { get set }

    /// The organization identifier being remembered on the single-sign on screen.
    var rememberedOrgIdentifier: String? { get set }

    /// The app's account state.
    var state: State? { get set }

    /// Whether the vault should sync on refreshing.
    ///
    /// - Parameter userId: The user ID associated with the sync on refresh setting.
    ///
    /// - Returns: Whether the vault should sync on refreshing.
    ///
    func allowSyncOnRefresh(userId: String) -> Bool

    /// Gets the time after which the clipboard should be cleared.
    ///
    /// - Parameter userId: The user ID associated with the clipboard clearing time.
    ///
    /// - Returns: The time after which the clipboard should be cleared.
    ///
    func clearClipboardValue(userId: String) -> ClearClipboardValue

    /// Gets the default URI match type.
    ///
    /// - Parameter userId: The user ID associated with the default URI match type.
    /// - Returns: The default URI match type.
    ///
    func defaultUriMatchType(userId: String) -> UriMatchType?

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

    /// Gets the disable auto-copy TOTP value for the user ID.
    ///
    /// - Parameter userId: The user ID associated with the disable auto-copy TOTP value.
    ///
    func disableAutoTotpCopy(userId: String) -> Bool

    /// Gets the time of the last sync for the user ID.
    ///
    /// - Parameter userId: The user ID associated with the last sync time.
    /// - Returns: The time of the last sync for the user.
    ///
    func lastSyncTime(userId: String) -> Date?

    /// Gets the master password hash for the user ID.
    ///
    /// - Parameter userId: The user ID associated with the master password hash.
    ///
    func masterPasswordHash(userId: String) -> String?

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

    /// Gets the number of unsuccessful attempts to unlock the vault for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the unsuccessful unlock attempts.
    /// - Returns: The number of unsuccessful attempts to unlock the vault.
    ///
    func unsuccessfulUnlockAttempts(userId: String) -> Int?

    /// Whether the vault should sync on refreshing.
    ///
    /// - Parameters:
    ///   - allowSyncOnRefresh: Whether the vault should sync on refreshing.
    ///   - userId: The user ID associated with the sync on refresh setting.
    ///
    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool?, userId: String)

    /// Sets the time after which the clipboard should be cleared.
    ///
    /// - Parameters:
    ///   - clearClipboardValue: The time after which the clipboard should be cleared.
    ///   - userId: The user ID associated with the clipboard clearing time.
    ///
    /// - Returns: The time after which the clipboard should be cleared.
    ///
    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String)

    /// Sets the default URI match type.
    ///
    /// - Parameters:
    ///   - uriMatchType: The default URI match type.
    ///   - userId: The user ID associated with the default URI match type.
    ///
    func setDefaultUriMatchType(_ uriMatchType: UriMatchType?, userId: String)

    /// Sets the disable auto-copy TOTP value for a user ID.
    ///
    /// - Parameters:
    ///   - disableAutoTotpCopy: The user's disable auto-copy TOTP value.
    ///   - userId: The user ID associated with the disable auto-copy TOTP value.
    ///
    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool?, userId: String)

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

    /// Sets the time of the last sync for the user ID.
    ///
    /// - Parameters:
    ///   - date: The time of the last sync.
    ///   - userId: The user ID associated with the last sync time.
    ///
    func setLastSyncTime(_ date: Date?, userId: String)

    /// Sets the master password hash for a user ID.
    ///
    /// - Parameters:
    ///   - hash: The user's master password hash.
    ///   - userId: The user ID associated with the master password hash.
    ///
    func setMasterPasswordHash(_ hash: String?, userId: String)

    /// Sets the password generation options for a user ID.
    ///
    /// - Parameters:
    ///   - options: The user's password generation options.
    ///   - userId: The user ID associated with the password generation options.
    ///
    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String)

    /// Sets the number of unsuccessful attempts to unlock the vault for a user ID.
    ///
    /// - Parameters:
    ///  -  attempts: The number of unsuccessful unlock attempts..
    ///  -  userId: The user ID associated with the unsuccessful unlock attempts.
    ///
    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String)

    /// Sets the username generation options for a user ID.
    ///
    /// - Parameters:
    ///   - options: The user's username generation options.
    ///   - userId: The user ID associated with the username generation options.
    ///
    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String)

    // MARK: Publishers

    /// A publisher for the active account id
    ///
    /// - Returns: The userId `String` of the active account
    ///
    func activeAccountIdPublisher() -> AsyncPublisher<AnyPublisher<String?, Never>>
}

// MARK: - DefaultAppSettingsStore

/// A default `AppSettingsStore` which persists app settings in `UserDefaults`.
///
class DefaultAppSettingsStore {
    // MARK: Properties

    /// The `UserDefaults` instance to persist settings.
    let userDefaults: UserDefaults

    /// A subject containing a `String?` for the userId of the active account..
    lazy var activeAccountIdSubject = CurrentValueSubject<String?, Never>(state?.activeUserId)

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
    private func fetch(for key: Keys) -> Int? {
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
        case allowSyncOnRefresh(userId: String)
        case appId
        case appLocale
        case appTheme
        case clearClipboardValue(userId: String)
        case defaultUriMatch(userId: String)
        case disableWebIcons
        case encryptedPrivateKey(userId: String)
        case encryptedUserKey(userId: String)
        case disableAutoTotpCopy(userId: String)
        case lastSync(userId: String)
        case masterPasswordHash(userId: String)
        case passwordGenerationOptions(userId: String)
        case preAuthEnvironmentUrls
        case rememberedEmail
        case rememberedOrgIdentifier
        case state
        case unsuccessfulUnlockAttempts(userId: String)
        case usernameGenerationOptions(userId: String)

        /// Returns the key used to store the data under for retrieving it later.
        var storageKey: String {
            let key: String
            switch self {
            case let .allowSyncOnRefresh(userId):
                key = "syncOnRefresh_\(userId)"
            case .appId:
                key = "appId"
            case .appLocale:
                key = "appLocale"
            case .appTheme:
                key = "theme"
            case let .clearClipboardValue(userId):
                key = "clearClipboard_\(userId)"
            case let .defaultUriMatch(userId):
                key = "defaultUriMatch_\(userId)"
            case .disableWebIcons:
                key = "disableFavicon"
            case let .encryptedUserKey(userId):
                key = "masterKeyEncryptedUserKey_\(userId)"
            case let .encryptedPrivateKey(userId):
                key = "encPrivateKey_\(userId)"
            case let .disableAutoTotpCopy(userId):
                key = "disableAutoTotpCopy_\(userId)"
            case let .lastSync(userId):
                key = "lastSync_\(userId)"
            case let .masterPasswordHash(userId):
                key = "keyHash_\(userId)"
            case let .passwordGenerationOptions(userId):
                key = "passwordGenerationOptions_\(userId)"
            case .preAuthEnvironmentUrls:
                key = "preAuthEnvironmentUrls"
            case .rememberedEmail:
                key = "rememberedEmail"
            case .rememberedOrgIdentifier:
                key = "rememberedOrgIdentifier"
            case .state:
                key = "state"
            case let .unsuccessfulUnlockAttempts(userId):
                key = "invalidUnlockAttempts_\(userId)"
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

    var preAuthEnvironmentUrls: EnvironmentUrlData? {
        get { fetch(for: .preAuthEnvironmentUrls) }
        set { store(newValue, for: .preAuthEnvironmentUrls) }
    }

    var rememberedEmail: String? {
        get { fetch(for: .rememberedEmail) }
        set { store(newValue, for: .rememberedEmail) }
    }

    var rememberedOrgIdentifier: String? {
        get { fetch(for: .rememberedOrgIdentifier) }
        set { store(newValue, for: .rememberedOrgIdentifier) }
    }

    var state: State? {
        get { fetch(for: .state) }
        set {
            activeAccountIdSubject.send(newValue?.activeUserId)
            return store(newValue, for: .state)
        }
    }

    func allowSyncOnRefresh(userId: String) -> Bool {
        fetch(for: .allowSyncOnRefresh(userId: userId))
    }

    func clearClipboardValue(userId: String) -> ClearClipboardValue {
        if let rawValue: Int = fetch(for: .clearClipboardValue(userId: userId)),
           let value = ClearClipboardValue(rawValue: rawValue) {
            return value
        }
        return .never
    }

    func encryptedPrivateKey(userId: String) -> String? {
        fetch(for: .encryptedPrivateKey(userId: userId))
    }

    func encryptedUserKey(userId: String) -> String? {
        fetch(for: .encryptedUserKey(userId: userId))
    }

    func defaultUriMatchType(userId: String) -> UriMatchType? {
        fetch(for: .defaultUriMatch(userId: userId))
    }

    func disableAutoTotpCopy(userId: String) -> Bool {
        fetch(for: .disableAutoTotpCopy(userId: userId))
    }

    func lastSyncTime(userId: String) -> Date? {
        fetch(for: .lastSync(userId: userId)).map { Date(timeIntervalSince1970: $0) }
    }

    func masterPasswordHash(userId: String) -> String? {
        fetch(for: .masterPasswordHash(userId: userId))
    }

    func passwordGenerationOptions(userId: String) -> PasswordGenerationOptions? {
        fetch(for: .passwordGenerationOptions(userId: userId))
    }

    func unsuccessfulUnlockAttempts(userId: String) -> Int? {
        fetch(for: .unsuccessfulUnlockAttempts(userId: userId))
    }

    func usernameGenerationOptions(userId: String) -> UsernameGenerationOptions? {
        fetch(for: .usernameGenerationOptions(userId: userId))
    }

    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool?, userId: String) {
        store(allowSyncOnRefresh, for: .allowSyncOnRefresh(userId: userId))
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String) {
        store(clearClipboardValue?.rawValue, for: .clearClipboardValue(userId: userId))
    }

    func setDefaultUriMatchType(_ uriMatchType: UriMatchType?, userId: String) {
        store(uriMatchType, for: .defaultUriMatch(userId: userId))
    }

    func setEncryptedPrivateKey(key: String?, userId: String) {
        store(key, for: .encryptedPrivateKey(userId: userId))
    }

    func setEncryptedUserKey(key: String?, userId: String) {
        store(key, for: .encryptedUserKey(userId: userId))
    }

    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool?, userId: String) {
        store(disableAutoTotpCopy, for: .disableAutoTotpCopy(userId: userId))
    }

    func setLastSyncTime(_ date: Date?, userId: String) {
        store(date?.timeIntervalSince1970, for: .lastSync(userId: userId))
    }

    func setMasterPasswordHash(_ hash: String?, userId: String) {
        store(hash, for: .masterPasswordHash(userId: userId))
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String) {
        store(options, for: .passwordGenerationOptions(userId: userId))
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String) {
        store(options, for: .usernameGenerationOptions(userId: userId))
    }

    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String) {
        store(attempts, for: .unsuccessfulUnlockAttempts(userId: userId))
    }

    func activeAccountIdPublisher() -> AsyncPublisher<AnyPublisher<String?, Never>> {
        activeAccountIdSubject
            .eraseToAnyPublisher()
            .values
    }
}
