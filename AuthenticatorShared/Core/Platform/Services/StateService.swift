import BitwardenKit
import Combine
import Foundation

// MARK: - StateService

/// A protocol for a `StateService` which manages the saved state of the app
///
protocol StateService: AnyObject {
    /// The language option currently selected for the app.
    var appLanguage: LanguageOption { get set }

    /// Whether the user has seen the welcome tutorial.
    ///
    var hasSeenWelcomeTutorial: Bool { get set }

    /// Gets the active account id.
    ///
    /// - Returns: The active user account id.
    ///
    func getActiveAccountId() async -> String

    /// Get the app theme.
    ///
    /// - Returns: The app theme.
    ///
    func getAppTheme() async -> AppTheme

    /// Get the active user's Biometric Authentication Preference.
    ///
    /// - Returns: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///
    func getBiometricAuthenticationEnabled() async throws -> Bool

    /// Gets the BiometricIntegrityState for the active user.
    ///
    /// - Returns: An optional base64 string encoding of the BiometricIntegrityState `Data` as last stored for the user.
    ///
    func getBiometricIntegrityState() async throws -> String?

    /// Gets the clear clipboard value for an account.
    ///
    /// - Parameter userId: The user ID associated with the clear clipboard value. Defaults to the active
    ///   account if `nil`
    /// - Returns: The time after which the clipboard should clear.
    ///
    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue

    /// Gets the data for the flight recorder.
    ///
    /// - Returns: The flight recorder data.
    ///
    func getFlightRecorderData() async -> FlightRecorderData?

    /// Gets the user's encryption secret key.
    ///
    /// - Returns: The user's encryption secret key.
    ///
    func getSecretKey(userId: String?) async throws -> String?

    /// Get whether to show website icons.
    ///
    /// - Returns: Whether to show the website icons.
    ///
    func getShowWebIcons() async -> Bool

    /// Gets the session timeout value for the logged in user.
    ///
    /// - Returns: The session timeout value.
    ///
    func getVaultTimeout() async -> SessionTimeoutValue

    /// Sets the app theme.
    ///
    /// - Parameter appTheme: The new app theme.
    ///
    func setAppTheme(_ appTheme: AppTheme) async

    /// Sets the user's Biometric Authentication Preference.
    ///
    /// - Parameter isEnabled: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///
    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?) async throws

    /// Sets the BiometricIntegrityState for the active user.
    ///
    /// - Parameter base64State: A base64 string encoding of the BiometricIntegrityState `Data`.
    ///
    func setBiometricIntegrityState(_ base64State: String?) async throws

    /// Sets the clear clipboard value for an account.
    ///
    /// - Parameters:
    ///   - clearClipboardValue: The time after which to clear the clipboard.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws

    /// Sets the data for the flight recorder.
    ///
    func setFlightRecorderData(_ data: FlightRecorderData?) async

    /// Sets the user's encryption secret key.
    ///
    /// - Parameters:
    ///   - key: The key to set
    ///
    func setSecretKey(_ key: String, userId: String?) async throws

    /// Set whether to show the website icons.
    ///
    /// - Parameter showWebIcons: Whether to show the website icons.
    ///
    func setShowWebIcons(_ showWebIcons: Bool) async

    // MARK: Publishers

    /// A publisher for the app theme.
    ///
    /// - Returns: A publisher for the app theme.
    ///
    func appThemePublisher() async -> AnyPublisher<AppTheme, Never>

    /// A publisher for whether or not to show the web icons.
    ///
    /// - Returns: A publisher for whether or not to show the web icons.
    ///
    func showWebIconsPublisher() async -> AnyPublisher<Bool, Never>
}

// MARK: - StateServiceError

/// The errors thrown from a `StateService`.
///
enum StateServiceError: Error {
    /// There are no known accounts.
    case noAccounts

    /// There isn't an active account.
    case noActiveAccount

    /// The user has no pin protected user key.
    case noPinProtectedUserKey

    /// The user has no user key.
    case noEncUserKey
}

// MARK: - DefaultStateService

/// A default implementation of `StateService`.
///
actor DefaultStateService: StateService, ActiveAccountStateProvider, ConfigStateService, FlightRecorderStateService, LanguageStateService {
    // MARK: Properties

    /// The language option currently selected for the app.
    nonisolated var appLanguage: LanguageOption {
        get { LanguageOption(appSettingsStore.appLocale) }
        set { appSettingsStore.appLocale = newValue.value }
    }

    nonisolated var hasSeenWelcomeTutorial: Bool {
        get { appSettingsStore.hasSeenWelcomeTutorial }
        set { appSettingsStore.hasSeenWelcomeTutorial = newValue }
    }

    // MARK: Private Properties

    /// The service that persists app settings.
    let appSettingsStore: AppSettingsStore

    /// A subject containing the app theme.
    private var appThemeSubject: CurrentValueSubject<AppTheme, Never>

    /// The data store that handles performing data requests.
    private let dataStore: DataStore

    /// A subject containing whether to show the website icons.
    private var showWebIconsSubject: CurrentValueSubject<Bool, Never>

    // MARK: Initialization

    /// Initialize a `DefaultStateService`.
    ///
    /// - Parameters:
    ///  - appSettingsStore: The service that persists app settings.
    ///  - dataStore: The data store that handles performing data requests.
    ///
    init(
        appSettingsStore: AppSettingsStore,
        dataStore: DataStore,
    ) {
        self.appSettingsStore = appSettingsStore
        self.dataStore = dataStore

        appThemeSubject = CurrentValueSubject(AppTheme(appSettingsStore.appTheme))
        showWebIconsSubject = CurrentValueSubject(!appSettingsStore.disableWebIcons)
    }

    // MARK: Methods

    func getActiveAccountId() async -> String {
        appSettingsStore.localUserId
    }

    func getAppTheme() async -> AppTheme {
        AppTheme(appSettingsStore.appTheme)
    }

    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.clearClipboardValue(userId: userId)
    }

    func getFlightRecorderData() async -> FlightRecorderData? {
        appSettingsStore.flightRecorderData
    }

    func getPreAuthServerConfig() async -> ServerConfig? {
        appSettingsStore.preAuthServerConfig
    }

    func getSecretKey(userId: String?) async throws -> String? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.secretKey(userId: userId)
    }

    func getServerConfig(userId: String?) async throws -> ServerConfig? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.serverConfig(userId: userId)
    }

    func getShowWebIcons() async -> Bool {
        !appSettingsStore.disableWebIcons
    }

    func getVaultTimeout() async -> SessionTimeoutValue {
        let accountId = await getActiveAccountId()
        guard let rawValue = appSettingsStore.vaultTimeout(userId: accountId) else { return .never }

        return SessionTimeoutValue(rawValue: rawValue)
    }

    func setAppTheme(_ appTheme: AppTheme) async {
        appSettingsStore.appTheme = appTheme.value
        appThemeSubject.send(appTheme)
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setClearClipboardValue(clearClipboardValue, userId: userId)
    }

    func setFlightRecorderData(_ data: FlightRecorderData?) async {
        appSettingsStore.flightRecorderData = data
    }

    func setPreAuthServerConfig(config: ServerConfig) async {
        appSettingsStore.preAuthServerConfig = config
    }

    func setSecretKey(_ key: String, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setSecretKey(key, userId: userId)
    }

    func setServerConfig(_ config: ServerConfig?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setServerConfig(config, userId: userId)
    }

    func setShowWebIcons(_ showWebIcons: Bool) async {
        appSettingsStore.disableWebIcons = !showWebIcons
        showWebIconsSubject.send(showWebIcons)
    }

    // MARK: Publishers

    func appThemePublisher() async -> AnyPublisher<AppTheme, Never> {
        appThemeSubject.eraseToAnyPublisher()
    }

    func showWebIconsPublisher() async -> AnyPublisher<Bool, Never> {
        showWebIconsSubject.eraseToAnyPublisher()
    }

    // MARK: Private

    /// Returns the user ID for the active account.
    ///
    /// - Returns: The user ID for the active account.
    ///
    private func getActiveAccountUserId() throws -> String {
        appSettingsStore.localUserId
    }
}

// MARK: Biometrics

extension DefaultStateService {
    func getBiometricAuthenticationEnabled() async throws -> Bool {
        let userId = try getActiveAccountUserId()
        return appSettingsStore.isBiometricAuthenticationEnabled(userId: userId)
    }

    func getBiometricIntegrityState() async throws -> String? {
        let userId = try getActiveAccountUserId()
        return appSettingsStore.biometricIntegrityState(userId: userId)
    }

    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?) async throws {
        let userId = try getActiveAccountUserId()
        appSettingsStore.setBiometricAuthenticationEnabled(isEnabled, for: userId)
    }

    func setBiometricIntegrityState(_ base64State: String?) async throws {
        let userId = try getActiveAccountUserId()
        appSettingsStore.setBiometricIntegrityState(base64State, userId: userId)
    }
}
