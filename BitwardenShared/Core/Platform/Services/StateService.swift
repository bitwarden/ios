import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Combine
import Foundation

// swiftlint:disable file_length

// MARK: - StateService

/// A protocol for a `StateService` which manages the state of the accounts in the app.
///
protocol StateService: AnyObject {
    /// The language option currently selected for the app.
    var appLanguage: LanguageOption { get set }

    /// The organization identifier being remembered on the single-sign on screen.
    var rememberedOrgIdentifier: String? { get set }

    /// Adds a new account to the app's state after a successful login.
    ///
    /// - Parameter account: The `Account` to add.
    ///
    func addAccount(_ account: Account) async

    /// Clears the pins stored on device and in memory.
    ///
    func clearPins() async throws

    /// Deletes the current active account.
    ///
    func deleteAccount() async throws

    /// Returns whether the active account was switched in the extension. This compares the current
    /// active account in memory with what's stored on disk to determine if the account was switched.
    ///
    /// - Returns: Whether the active was switched in the extension.
    ///
    func didAccountSwitchInExtension() async throws -> Bool

    /// Returns whether the active user account has access to premium features.
    ///
    /// - Returns: Whether the active account has access to premium features.
    ///
    func doesActiveAccountHavePremium() async -> Bool

    /// Gets the access token's expiration date for an account.
    ///
    /// - Parameter userId: The user ID associated with the access token expiration date.
    /// - Returns: The user's access token expiration date.
    ///
    func getAccessTokenExpirationDate(userId: String) async -> Date?

    /// Gets the account for an id.
    ///
    /// - Parameter userId: The id for an account. If nil, the active account will be returned.
    /// - Returns: The account for the id.
    ///
    func getAccount(userId: String?) async throws -> Account

    /// Gets the account encryptions keys for an account.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: The account encryption keys.
    ///
    func getAccountEncryptionKeys(userId: String?) async throws -> AccountEncryptionKeys

    /// Gets whether the user has unlocked their account in the current session interactively.
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    func getAccountHasBeenUnlockedInteractively(userId: String?) async throws -> Bool

    /// Gets the user's progress for setting up autofill.
    ///
    /// - Parameter userId: The user ID associated with the autofill setup progress.
    /// - Returns: The user's autofill setup progress.
    ///
    func getAccountSetupAutofill(userId: String) async -> AccountSetupProgress?

    /// Gets the user's progress for importing logins.
    ///
    /// - Parameter userId: The user ID associated with the import logins setup progress.
    /// - Returns: The user's import logins setup progress.
    ///
    func getAccountSetupImportLogins(userId: String) async -> AccountSetupProgress?

    /// Gets the user's progress for setting up vault unlock.
    ///
    /// - Parameter userId: The user ID associated with the vault unlock setup progress.
    /// - Returns: The user's vault unlock setup progress.
    ///
    func getAccountSetupVaultUnlock(userId: String) async -> AccountSetupProgress?

    /// Gets all accounts.
    ///
    /// - Returns: The known user accounts.
    ///
    func getAccounts() async throws -> [Account]

    /// Gets the account id or the active account id for a possible id.
    ///
    /// - Parameter userId: The possible user Id of an account.
    /// - Returns: The user account id or the active id.
    ///
    func getAccountIdOrActiveId(userId: String?) async throws -> String

    /// Gets the active account.
    ///
    /// - Returns: The active user account.
    ///
    func getActiveAccount() async throws -> Account

    /// Gets the active account id.
    ///
    /// - Returns: The active user account id.
    ///
    func getActiveAccountId() async throws -> String

    /// Gets whether the autofill info prompt has been shown.
    ///
    /// - Returns: Whether the autofill info prompt has been shown.
    ///
    func getAddSitePromptShown() async -> Bool

    /// Gets the allow sync on refresh value for an account.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: The allow sync on refresh value.
    ///
    func getAllowSyncOnRefresh(userId: String?) async throws -> Bool

    /// Gets the Universal Clipboard setting for a user account.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: A Boolean value indicating whether Universal Clipboard is allowed.
    ///
    func getAllowUniversalClipboard(userId: String?) async throws -> Bool

    /// Gets the app rehydration state.
    /// - Parameter userId: The user ID associated with this state.
    /// - Returns: The rehydration state.
    func getAppRehydrationState(userId: String?) async throws -> AppRehydrationState?

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

    /// Gets the clear clipboard value for an account.
    ///
    /// - Parameter userId: The user ID associated with the clear clipboard value. Defaults to the active
    ///   account if `nil`
    /// - Returns: The time after which the clipboard should clear.
    ///
    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue

    /// Gets the connect to watch value for an account.
    ///
    /// - Parameter userId: The user ID associated with the connect to watch value. Defaults to the active
    ///   account if `nil`
    /// - Returns: Whether to connect to the watch app.
    ///
    func getConnectToWatch(userId: String?) async throws -> Bool

    /// Gets the default URI match type value for an account.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: The default URI match type value.
    ///
    func getDefaultUriMatchType(userId: String?) async -> UriMatchType

    /// Gets the disable auto-copy TOTP value for an account.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: The disable auto-copy TOTP value.
    ///
    func getDisableAutoTotpCopy(userId: String?) async throws -> Bool

    /// The user's pin protected by their user key.
    ///
    /// - Parameter userId: The user ID associated with the encrypted pin.
    /// - Returns: The user's pin protected by their user key.
    ///
    func getEncryptedPin(userId: String?) async throws -> String?

    /// Gets the environment URLs for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the environment URLs.
    /// - Returns: The user's environment URLs.
    ///
    func getEnvironmentURLs(userId: String?) async throws -> EnvironmentURLData?

    /// Gets the events stored to disk to be uploaded in the future.
    ///
    /// - Parameters:
    ///   - userId: The user ID associated with the events.
    /// - Returns: The events for the user
    ///
    func getEvents(userId: String?) async throws -> [EventData]

    /// Gets the data for the flight recorder.
    ///
    /// - Returns: The flight recorder data.
    ///
    func getFlightRecorderData() async -> FlightRecorderData?

    /// Gets whether a sync has been done successfully after login. This is particular useful to trigger logic that
    /// needs to be executed right after login in and after the first successful sync.
    ///
    /// - Parameter userId: The user ID associated with the sync after login.
    /// - Returns: `true` if sync has already been done after login, `false` otherwise.
    ///
    func getHasPerformedSyncAfterLogin(userId: String?) async throws -> Bool

    /// Gets whether the intro carousel screen has been shown.
    ///
    /// - Returns: Whether the intro carousel screen has been shown.
    ///
    func getIntroCarouselShown() async -> Bool

    /// Gets the user's last active time within the app.
    /// This value is set when the app is backgrounded.
    ///
    /// - Parameter userId: The user ID associated with the last active time within the app.
    /// - Returns: The date of the last active time.
    ///
    func getLastActiveTime(userId: String?) async throws -> Date?

    /// Gets the time of the last sync for a user.
    ///
    /// - Parameter userId: The user ID associated with the last sync time.
    /// - Returns: The user's last sync time.
    ///
    func getLastSyncTime(userId: String?) async throws -> Date?

    /// The last value of the connect to watch setting, ignoring the user id. Used for
    /// sending the status to the watch if the user is logged out.
    ///
    /// - Returns: The last known value of the `connectToWatch` setting.
    ///
    func getLastUserShouldConnectToWatch() async -> Bool

    /// Gets the status of Learn Generator Action Card.
    ///
    /// - Returns: The status of Learn generator Action Card.
    ///
    func getLearnGeneratorActionCardStatus() async -> AccountSetupProgress?

    /// Get any pending login request data.
    ///
    /// - Returns: The pending login request data from a push notification.
    ///
    func getLoginRequest() async -> LoginRequestNotification?

    /// Gets whether the account belonging to the user Id has been manually locked.
    /// - Parameter userId: The user ID associated with the account.
    /// - Returns: `true` if manually locked, `false` otherwise.
    func getManuallyLockedAccount(userId: String?) async throws -> Bool

    /// Gets the master password hash for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the master password hash.
    /// - Returns: The user's master password hash.
    ///
    func getMasterPasswordHash(userId: String?) async throws -> String?

    /// Gets the last notifications registration date for a user ID.
    ///
    /// - Parameter userId: The user ID of the account. Defaults to the active account if `nil`.
    /// - Returns: The last notifications registration date.
    ///
    func getNotificationsLastRegistrationDate(userId: String?) async throws -> Date?

    /// Gets the password generation options for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the password generation options.
    /// - Returns: The password generation options for the user ID.
    ///
    func getPasswordGenerationOptions(userId: String?) async throws -> PasswordGenerationOptions?

    /// Gets the pending actions from `AppIntent`s.
    /// - Returns: The pending actions to execute.
    func getPendingAppIntentActions() async -> [PendingAppIntentAction]?

    /// Gets the environment URLs used by the app prior to the user authenticating.
    ///
    /// - Returns: The environment URLs used prior to user authentication.
    ///
    func getPreAuthEnvironmentURLs() async -> EnvironmentURLData?

    /// Gets the environment URLs for a given email during account creation.
    ///
    /// - Parameter email: The email used to start the account creation.
    /// - Returns: The environment URLs used prior to start the account creation.
    ///
    func getAccountCreationEnvironmentURLs(email: String) async -> EnvironmentURLData?

    /// Gets the App Review Prompt data.
    ///
    /// - Returns: The App Review Prompt data.
    ///
    func getReviewPromptData() async -> ReviewPromptData?

    /// Get whether the device should be trusted.
    ///
    /// - Returns: Whether to trust the device.
    ///
    func getShouldTrustDevice(userId: String) async -> Bool?

    /// Gets the status of Learn New Login Action Card.
    ///
    /// - Returns: The status of Learn New Login Action Card.
    ///
    func getLearnNewLoginActionCardStatus() async -> AccountSetupProgress?

    /// Get whether to show the website icons.
    ///
    /// - Returns: Whether to show the website icons.
    ///
    func getShowWebIcons() async -> Bool

    /// Gets whether Siri & Shortcuts access is enabled.
    /// - Parameter userId: The user ID.
    /// - Returns: Whether Siri & Shortcuts access is enabled.
    func getSiriAndShortcutsAccess(userId: String?) async throws -> Bool

    /// Gets the sync to Authenticator value for an account.
    ///
    /// - Parameter userId: The user ID associated with the sync to Authenticator value. Defaults to the active
    ///   account if `nil`
    /// - Returns: Whether to sync TOPT codes to the Authenticator app.
    ///
    func getSyncToAuthenticator(userId: String?) async throws -> Bool

    /// Gets the session timeout action.
    ///
    /// - Parameter userId: The user ID for the account.
    /// - Returns: The action to perform when a session timeout occurs.
    ///
    func getTimeoutAction(userId: String?) async throws -> SessionTimeoutAction

    /// Get the two-factor token (non-nil if the user selected the "remember me" option).
    ///
    /// - Parameter email: The user's email address.
    /// - Returns: The two-factor token.
    ///
    func getTwoFactorToken(email: String) async -> String?

    /// Gets the number of unsuccessful attempts to unlock the vault for a user ID.
    ///
    /// - Parameter userId: The optional user ID associated with the unsuccessful unlock attempts,
    /// if `nil` defaults to currently active user.
    /// - Returns: The number of unsuccessful attempts to unlock the vault.
    ///
    func getUnsuccessfulUnlockAttempts(userId: String?) async throws -> Int

    /// Gets whether a user has a master password.
    ///
    /// - Parameter userId: The user ID of the user to determine whether they have a master password.
    /// - Returns: Whether the user has a master password.
    ///
    func getUserHasMasterPassword(userId: String?) async throws -> Bool

    /// Gets the user ID of any accounts with the specified email.
    ///
    /// - Parameter email: The email of the account.
    /// - Returns: A list of user IDs for the accounts with a matching email.
    ///
    func getUserIds(email: String) async -> [String]

    /// Gets the username generation options for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the username generation options.
    /// - Returns: The username generation options for the user ID.
    ///
    func getUsernameGenerationOptions(userId: String?) async throws -> UsernameGenerationOptions?

    /// Gets whether the user uses key connector.
    ///
    /// - Parameter userId: The user ID to check if they use key connector.
    /// - Returns: Whether the user uses key connector.
    ///
    func getUsesKeyConnector(userId: String?) async throws -> Bool

    /// Gets the session timeout value.
    ///
    /// - Parameter userId: The user ID for the account.
    /// - Returns: The session timeout value.
    ///
    func getVaultTimeout(userId: String?) async throws -> SessionTimeoutValue

    /// Whether the user is authenticated.
    ///
    /// - Parameter userId: The user ID to check if they are authenticated.
    /// - Returns: Whether the user is authenticated.
    ///
    func isAuthenticated(userId: String?) async throws -> Bool

    /// Logs the user out of an account.
    ///
    /// - Parameters:
    ///   - userId: The user ID of the account to log out of. Defaults to the active account if `nil`.
    ///   - userInitiated: Whether the logout was user initiated or a result of a logout timeout action.
    ///
    func logoutAccount(userId: String?, userInitiated: Bool) async throws

    /// The pin protected user key.
    ///
    /// - Note: This is being replaced by ``pinProtectedUserKeyEnvelope(userId:)``.
    ///
    /// - Parameter userId: The user ID associated with the pin protected user key.
    /// - Returns: The user's pin protected user key.
    ///
    func pinProtectedUserKey(userId: String?) async throws -> String?

    /// The pin protected user key envelope.
    ///
    /// - Parameter userId: The user ID associated with the pin protected user key envelope.
    /// - Returns: The user's pin protected user key envelope.
    ///
    func pinProtectedUserKeyEnvelope(userId: String?) async throws -> String?

    /// Whether pin unlock requires the user to enter their master password or use biometrics after
    /// an app restart.
    ///
    /// - Returns: Whether pin unlock the user to enter their master password or use biometrics
    ///     after an app restart.
    ///
    func pinUnlockRequiresPasswordAfterRestart() async throws -> Bool

    /// Sets the access token's expiration date for an account.
    ///
    /// - Parameters:
    ///   - expirationDate: The user's access token expiration date.
    ///   - userId: The user ID associated with the access token expiration date.
    ///
    func setAccessTokenExpirationDate(_ expirationDate: Date?, userId: String) async

    /// Sets the account encryption keys for an account.
    ///
    /// - Parameters:
    ///   - encryptionKeys: The account encryption keys.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String?) async throws

    /// Sets whether the user has unlocked their account in the current session  interactively.
    /// - Parameters:
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///   - value: Whether the user has unlocked their account in the current session.
    func setAccountHasBeenUnlockedInteractively(userId: String?, value: Bool) async throws

    /// Sets the KDF config for an account.
    ///
    /// - Parameters:
    ///   - kdfConfig: The account's KDF config.
    ///   - userId: The user ID of the account to set the KDF config for.
    ///
    func setAccountKdf(_ kdfConfig: KdfConfig, userId: String) async throws

    /// Sets the master password unlock data for an account.
    ///
    /// - Parameters:
    ///   - masterPasswordUnlock: The account master password unlock data.
    ///   - userId: The user ID of the account to associate with the master password unlock data.
    ///
    func setAccountMasterPasswordUnlock(
        _ masterPasswordUnlock: MasterPasswordUnlockResponseModel,
        userId: String,
    ) async

    /// Sets the user's progress for setting up autofill.
    ///
    /// - Parameters:
    ///   - autofillSetup: The user's autofill setup progress.
    ///   - userId: The user ID associated with the autofill setup progress.
    ///
    func setAccountSetupAutofill(_ autofillSetup: AccountSetupProgress?, userId: String?) async throws

    /// Sets the user's progress for setting up import logins.
    ///
    /// - Parameters:
    ///   - importLogins: The user's import logins setup progress.
    ///   - userId: The user ID associated with the import logins setup progress.
    ///
    func setAccountSetupImportLogins(_ importLogins: AccountSetupProgress?, userId: String?) async throws

    /// Sets the user's progress for setting up vault unlock.
    ///
    /// - Parameters:
    ///   - autofillSetup: The user's vault unlock setup progress.
    ///   - userId: The user ID associated with the vault unlock setup progress.
    ///
    func setAccountSetupVaultUnlock(_ vaultUnlockSetup: AccountSetupProgress?, userId: String?) async throws

    /// Sets the active account.
    ///
    /// - Parameter userId: The user Id of the account to set as active.
    ///
    func setActiveAccount(userId: String) async throws

    /// Sets whether the autofill info prompt has been shown.
    ///
    /// - Parameter shown: Whether the autofill info prompt has been shown.
    ///
    func setAddSitePromptShown(_ shown: Bool) async

    /// Sets the allow sync on refresh value for an account.
    ///
    /// - Parameters:
    ///   - allowSyncOnRefresh: Whether to allow sync on refresh.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool, userId: String?) async throws

    /// Sets the Universal Clipboard setting for a user account.
    ///
    /// - Parameters:
    ///   - allowUniversalClipboard: A Boolean value indicating whether Universal Clipboard should be allowed.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setAllowUniversalClipboard(_ allowUniversalClipboard: Bool, userId: String?) async throws

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

    /// Sets the clear clipboard value for an account.
    ///
    /// - Parameters:
    ///   - clearClipboardValue: The time after which to clear the clipboard.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws

    /// Sets the connect to watch value for an account.
    ///
    /// - Parameters:
    ///   - connectToWatch: Whether to connect to the watch app.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setConnectToWatch(_ connectToWatch: Bool, userId: String?) async throws

    /// Sets the default URI match type value for an account.
    ///
    /// - Parameters:
    ///   - defaultUriMatchType: The default URI match type.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setDefaultUriMatchType(_ defaultUriMatchType: UriMatchType?, userId: String?) async throws

    /// Sets the disable auto-copy TOTP value for an account.
    ///
    /// - Parameters:
    ///   - disableAutoTotpCopy: Whether the TOTP for a cipher should be auto-copied.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool, userId: String?) async throws

    /// Sets the events saved to disk for future upload.
    ///
    /// - Parameters:
    ///   - events: The events to save.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setEvents(_ events: [EventData], userId: String?) async throws

    /// Sets the force password reset reason for an account.
    ///
    /// - Parameters:
    ///   - reason: The reason why a password reset is required.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setForcePasswordResetReason(_ reason: ForcePasswordResetReason?, userId: String?) async throws

    /// Sets whether a sync has been done successfully after login. This is particular useful to trigger logic that
    /// needs to be executed right after login in and after the first successful sync.
    ///
    /// - Parameters:
    ///   - hasBeenPerformed: Whether a sync has been performed after login.
    ///   - userId: The user ID associated with the sync after login.
    func setHasPerformedSyncAfterLogin(_ hasBeenPerformed: Bool, userId: String?) async throws

    /// Sets the data for the flight recorder.
    ///
    func setFlightRecorderData(_ data: FlightRecorderData?) async

    /// Sets whether the intro carousel screen has been shown.
    ///
    /// - Parameter shown: Whether the intro carousel screen has been shown.
    ///
    func setIntroCarouselShown(_ shown: Bool) async

    /// Sets the status of Learn generator Action Card.
    ///
    /// - Parameter status: The status of Learn generator Action Card.
    ///
    func setLearnGeneratorActionCardStatus(_ status: AccountSetupProgress) async

    /// Sets the status of Learn New Login Action Card.
    ///
    /// - Parameter status: The status of Learn New Login Action Card.
    ///
    func setLearnNewLoginActionCardStatus(_ status: AccountSetupProgress) async

    /// Sets the last active time within the app.
    ///
    /// - Parameters:
    ///   - date: The current time.
    ///   - userId: The user ID associated with the last active time within the app.
    ///
    func setLastActiveTime(_ date: Date?, userId: String?) async throws

    /// Sets the time of the last sync for a user ID.
    ///
    /// - Parameters:
    ///   - date: The time of the last sync.
    ///   - userId: The user ID associated with the last sync time.
    ///
    func setLastSyncTime(_ date: Date?, userId: String?) async throws

    /// Set pending login request data from a push notification.
    ///
    /// - Parameter loginRequest: The pending login request data.
    ///
    func setLoginRequest(_ loginRequest: LoginRequestNotification?) async

    /// Sets whether the account belonging to the user Id has been manually locked.
    /// - Parameters
    ///   - isLocked: Whether the account has been locked manually.
    ///   - userId: The user ID associated with the account.
    /// - Returns: `true` if manually locked, `false` otherwise.
    func setManuallyLockedAccount(_ isLocked: Bool, userId: String?) async throws

    /// Sets the master password hash for a user ID.
    ///
    /// - Parameters:
    ///   - hash: The user's master password hash.
    ///   - userId: The user ID associated with the master password hash.
    ///
    func setMasterPasswordHash(_ hash: String?, userId: String?) async throws

    /// Sets the last notifications registration date for a user ID.
    ///
    /// - Parameters:
    ///   - date: The last notifications registration date.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setNotificationsLastRegistrationDate(_ date: Date?, userId: String?) async throws

    /// Sets the password generation options for a user ID.
    ///
    /// - Parameters:
    ///   - options: The user's password generation options.
    ///   - userId: The user ID associated with the password generation options.
    ///
    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String?) async throws

    /// Sets the pending actions from `AppIntent`s.
    /// - Parameter actions: Actions pending to be executed.
    func setPendingAppIntentActions(actions: [PendingAppIntentAction]?) async

    /// Set's the pin keys.
    ///
    /// - Parameters:
    ///   - enrollPinResponse: The user's pin keys from enrolling a pin.
    ///   - requirePasswordAfterRestart: Whether to require password after app restart.
    ///
    func setPinKeys(
        enrollPinResponse: EnrollPinResponse,
        requirePasswordAfterRestart: Bool,
    ) async throws

    /// Sets the pin protected user key to memory.
    ///
    /// - Parameter pin: The user's pin.
    ///
    func setPinProtectedUserKeyToMemory(_ pin: String) async throws

    /// Sets the environment URLs used prior to user authentication.
    ///
    /// - Parameter urls: The environment URLs used prior to user authentication.
    ///
    func setPreAuthEnvironmentURLs(_ urls: EnvironmentURLData) async

    /// Sets the environment URLs for a given email during account creation.
    /// - Parameters:
    ///   - urls: The environment urls used to start the account creation.
    ///   - email: The email used to start the account creation.
    ///
    func setAccountCreationEnvironmentURLs(urls: EnvironmentURLData, email: String) async

    /// Sets the app rehydration state for the active account.
    /// - Parameters:
    ///   - rehydrationState: The app rehydration state.
    ///   - userId: The user ID of the rehydration state.
    func setAppRehydrationState(_ rehydrationState: AppRehydrationState?, userId: String?) async throws

    /// Sets the App Review Prompt data.
    ///
    /// - Parameter data: The App Review Prompt data.
    ///
    func setReviewPromptData(_ data: ReviewPromptData) async

    /// Set whether to trust the device.
    ///
    /// - Parameter shouldTrustDevice: Whether to trust the device.
    ///
    func setShouldTrustDevice(_ shouldTrustDevice: Bool?, userId: String) async

    /// Set whether to show the website icons.
    ///
    /// - Parameter showWebIcons: Whether to show the website icons.
    ///
    func setShowWebIcons(_ showWebIcons: Bool) async

    /// Set whether to allow access to Siri & Shortcuts using `AppIntent`.
    ///
    /// - Parameters:
    ///   - siriAndShortcutsAccess: Whether access is enabled.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    func setSiriAndShortcutsAccess(_ siriAndShortcutsAccess: Bool, userId: String?) async throws

    /// Sets the sync to authenticator value for an account.
    ///
    /// - Parameters:
    ///   - syncToAuthenticator: Whether to sync TOTP codes to the Authenticator app.
    ///   - userId: The user ID of the account. Defaults to the active account if `nil`.
    ///
    func setSyncToAuthenticator(_ syncToAuthenticator: Bool, userId: String?) async throws

    /// Sets the session timeout action.
    ///
    /// - Parameters:
    ///   - action: The action to take when the user's session times out.
    ///   - userId: The user ID associated with the timeout action.
    ///
    func setTimeoutAction(action: SessionTimeoutAction, userId: String?) async throws

    /// Sets the user's two-factor token.
    ///
    /// - Parameters:
    ///   - token: The two-factor token.
    ///   - email: The user's email address.
    ///
    func setTwoFactorToken(_ token: String?, email: String) async

    /// Sets the number of unsuccessful attempts to unlock the vault for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the unsuccessful unlock attempts.
    /// if `nil` defaults to currently active user.
    ///
    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String?) async throws

    /// Sets whether the user has a master password.
    ///
    /// - Parameter hasMasterPassword: Whether the user has a master password.
    ///
    func setUserHasMasterPassword(_ hasMasterPassword: Bool) async throws

    /// Sets the username generation options for a user ID.
    ///
    /// - Parameters:
    ///   - options: The user's username generation options.
    ///   - userId: The user ID associated with the username generation options.
    ///
    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String?) async throws

    /// Sets whether the user uses key connector.
    ///
    /// - Parameters:
    ///   - usesKeyConnector: Whether the user uses key connector.
    ///   - userId: The user ID to set whether they use key connector.
    ///
    func setUsesKeyConnector(_ usesKeyConnector: Bool, userId: String?) async throws

    /// Sets the session timeout value.
    ///
    /// - Parameters:
    ///   - value: The value that dictates how many seconds in the future a timeout should occur.
    ///   - userId: The user ID associated with the timeout value.
    ///
    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws

    /// Updates the profile information for a user.
    ///
    /// - Parameters:
    ///   - response: The profile response information to use while updating.
    ///   - userId: The id of the user this updated information belongs to.
    ///
    func updateProfile(from response: ProfileResponseModel, userId: String) async

    // MARK: Publishers

    /// A publisher for the active account id
    ///
    /// - Returns: The userId `String` of the active account
    ///
    func activeAccountIdPublisher() async -> AnyPublisher<String?, Never>

    /// A publisher for the app theme.
    ///
    /// - Returns: A publisher for the app theme.
    ///
    func appThemePublisher() async -> AnyPublisher<AppTheme, Never>

    /// A publisher for the connect to watch value.
    ///
    /// - Returns: A publisher for the connect to watch value.
    ///
    func connectToWatchPublisher() async -> AnyPublisher<(String?, Bool), Never>

    /// A publisher for the last sync time for the active account.
    ///
    /// - Returns: A publisher for the last sync time.
    ///
    func lastSyncTimePublisher() async throws -> AnyPublisher<Date?, Never>

    /// A publisher for the pending App Intent actions.
    ///
    /// - Returns: A publisher for the pending App Intent actions.
    ///
    func pendingAppIntentActionsPublisher() async -> AnyPublisher<[PendingAppIntentAction]?, Never>

    /// A publisher for showing badges in the settings tab.
    ///
    /// - Returns: A publisher for showing badges in the settings tab.
    ///
    func settingsBadgePublisher() async throws -> AnyPublisher<SettingsBadgeState, Never>

    /// A publisher for whether or not to show the web icons.
    ///
    /// - Returns: A publisher for whether or not to show the web icons.
    ///
    func showWebIconsPublisher() async -> AnyPublisher<Bool, Never>

    /// A publisher for the sync to authenticator value.
    ///
    /// - Returns: A publisher for the sync to authenticator value.
    ///
    func syncToAuthenticatorPublisher() async -> AnyPublisher<(String?, Bool), Never>
}

extension StateService {
    /// Appends the `action` to the current pending `AppIntent` actions.
    func addPendingAppIntentAction(_ action: PendingAppIntentAction) async {
        var actions = await getPendingAppIntentActions() ?? []
        guard !actions.contains(action) else {
            return
        }
        actions.append(action)
        await setPendingAppIntentActions(actions: actions)
    }

    /// Gets the access token's expiration date for the active account.
    ///
    /// - Returns: The user's access token expiration date.
    ///
    func getAccessTokenExpirationDate() async throws -> Date? {
        try await getAccessTokenExpirationDate(userId: getActiveAccountId())
    }

    /// Gets the account encryptions keys for the active account.
    ///
    /// - Returns: The account encryption keys.
    ///
    func getAccountEncryptionKeys() async throws -> AccountEncryptionKeys {
        try await getAccountEncryptionKeys(userId: nil)
    }

    /// Gets whether the user has unlocked their account in the current session  interactively.
    func getAccountHasBeenUnlockedInteractively() async throws -> Bool {
        try await getAccountHasBeenUnlockedInteractively(userId: nil)
    }

    /// Gets either a valid account id or the active account id.
    ///
    /// - Parameter userId: The possible user id.
    ///     If `nil`, this method will attempt to return the active account id.
    ///     If non-nil, this method will validate the user id.
    /// - Returns: A valid user id.
    ///
    func getAccountIdOrActiveId(userId: String?) async throws -> String {
        try await getAccount(userId: userId).profile.userId
    }

    /// Gets the active user's progress for setting up autofill.
    ///
    /// - Returns: The user's autofill setup progress.
    ///
    func getAccountSetupAutofill() async throws -> AccountSetupProgress? {
        try await getAccountSetupAutofill(userId: getActiveAccountId())
    }

    /// Gets the active user's progress for importing logins.
    ///
    /// - Returns: The user's import logins setup progress.
    ///
    func getAccountSetupImportLogins() async throws -> AccountSetupProgress? {
        try await getAccountSetupImportLogins(userId: getActiveAccountId())
    }

    /// Gets the active user's progress for setting up vault unlock.
    ///
    /// - Returns: The user's vault unlock setup progress.
    ///
    func getAccountSetupVaultUnlock() async throws -> AccountSetupProgress? {
        try await getAccountSetupVaultUnlock(userId: getActiveAccountId())
    }

    /// Gets the active account id.
    ///
    /// - Returns: The active user id.
    ///
    func getActiveAccountId() async throws -> String {
        try await getActiveAccount().profile.userId
    }

    /// Gets the active account.
    ///
    /// - Returns: The active user account.
    ///
    func getActiveAccount() async throws -> Account {
        do {
            return try await getAccount(userId: nil)
        } catch {
            throw StateServiceError.noActiveAccount
        }
    }

    /// Gets the allow sync on refresh value for the active account.
    ///
    /// - Returns: The allow sync on refresh value.
    ///
    func getAllowSyncOnRefresh() async throws -> Bool {
        try await getAllowSyncOnRefresh(userId: nil)
    }

    /// Gets the Universal Clipboard setting for the active account.
    ///
    /// - Returns: A Boolean value indicating whether Universal Clipboard is allowed.
    ///
    func getAllowUniversalClipboard() async throws -> Bool {
        try await getAllowUniversalClipboard(userId: nil)
    }

    /// Gets the app rehydration state for the active account.
    /// - Returns: The rehydration state.
    func getAppRehydrationState() async throws -> AppRehydrationState? {
        try await getAppRehydrationState(userId: nil)
    }

    /// Gets the clear clipboard value for the active account.
    ///
    /// - Returns: The clear clipboard value.
    ///
    func getClearClipboardValue() async throws -> ClearClipboardValue {
        try await getClearClipboardValue(userId: nil)
    }

    /// Gets the connect to watch value for the active account.
    ///
    /// - Returns: Whether to connect to the watch app.
    ///
    func getConnectToWatch() async throws -> Bool {
        try await getConnectToWatch(userId: nil)
    }

    /// Gets the default URI match type value for the active account.
    ///
    /// - Returns: The default URI match type value.
    ///
    func getDefaultUriMatchType() async -> UriMatchType {
        await getDefaultUriMatchType(userId: nil)
    }

    /// Gets the disable auto-copy TOTP value for the active account.
    ///
    /// - Returns: The disable auto-copy TOTP value.
    ///
    func getDisableAutoTotpCopy() async throws -> Bool {
        try await getDisableAutoTotpCopy(userId: nil)
    }

    /// The user's pin protected by their user key.
    ///
    /// - Returns: The user's pin protected by their user key.
    ///
    func getEncryptedPin() async throws -> String? {
        try await getEncryptedPin(userId: nil)
    }

    /// Gets the environment URLs for the active account.
    ///
    /// - Returns: The environment URLs for the active account.
    ///
    func getEnvironmentURLs() async throws -> EnvironmentURLData? {
        try await getEnvironmentURLs(userId: nil)
    }

    /// Gets whether a sync has been done successfully after login for the current user.
    /// This is particular useful to trigger logic that needs to be executed right after login in
    /// and after the first successful sync.
    ///
    /// - Returns: `true` if sync has already been done after login, `false` otherwise.
    ///
    func getHasPerformedSyncAfterLogin() async throws -> Bool {
        try await getHasPerformedSyncAfterLogin(userId: nil)
    }

    /// Gets the user's last active time within the app.
    /// This value is set when the app is backgrounded.
    ///
    /// - Returns: The date of the last active time.
    ///
    func getLastActiveTime() async throws -> Date? {
        try await getLastActiveTime(userId: nil)
    }

    /// Gets the time of the last sync for a user.
    ///
    /// - Parameter userId: The user ID associated with the last sync time.
    /// - Returns: The user's last sync time.
    ///
    func getLastSyncTime() async throws -> Date? {
        try await getLastSyncTime(userId: nil)
    }

    /// Gets the master password hash for the active account.
    ///
    /// - Returns: The user's master password hash.
    ///
    func getMasterPasswordHash() async throws -> String? {
        try await getMasterPasswordHash(userId: nil)
    }

    /// Gets the last notifications registration date for the active account.
    ///
    /// - Returns: The last notifications registration date for the active account.
    ///
    func getNotificationsLastRegistrationDate() async throws -> Date? {
        try await getNotificationsLastRegistrationDate(userId: nil)
    }

    /// Gets the password generation options for the active account.
    ///
    /// - Returns: The password generation options for the user ID.
    ///
    func getPasswordGenerationOptions() async throws -> PasswordGenerationOptions? {
        try await getPasswordGenerationOptions(userId: nil)
    }

    /// Gets whether Siri & Shortcuts access is enabled for the active account.
    /// - Returns: Whether Siri & Shortcuts access is enabled.
    func getSiriAndShortcutsAccess() async throws -> Bool {
        try await getSiriAndShortcutsAccess(userId: nil)
    }

    /// Gets the sync to authenticator value for the active account.
    ///
    /// - Returns: Whether to sync TOTP codes to the Authenticator app.
    ///
    func getSyncToAuthenticator() async throws -> Bool {
        try await getSyncToAuthenticator(userId: nil)
    }

    /// Gets the session timeout action.
    ///
    /// - Returns: The action to perform when a session timeout occurs.
    ///
    func getTimeoutAction() async throws -> SessionTimeoutAction {
        try await getTimeoutAction(userId: nil)
    }

    /// Sets the number of unsuccessful attempts to unlock the vault for the active account.
    ///
    /// - Returns: The number of unsuccessful unlock attempts for the active account.
    ///
    func getUnsuccessfulUnlockAttempts() async -> Int {
        if let attempts = try? await getUnsuccessfulUnlockAttempts(userId: nil) {
            return attempts
        }
        return 0
    }

    /// Gets whether a user has a master password.
    ///
    /// - Returns: Whether the user has a master password.
    ///
    func getUserHasMasterPassword() async throws -> Bool {
        try await getUserHasMasterPassword(userId: nil)
    }

    /// Gets the username generation options for the active account.
    ///
    /// - Returns: The username generation options for the user ID.
    ///
    func getUsernameGenerationOptions() async throws -> UsernameGenerationOptions? {
        try await getUsernameGenerationOptions(userId: nil)
    }

    /// Gets whether the user uses key connector.
    ///
    /// - Returns: Whether the user uses key connector.
    ///
    func getUsesKeyConnector() async throws -> Bool {
        try await getUsesKeyConnector(userId: nil)
    }

    /// Gets the session timeout value.
    ///
    /// - Returns: The session timeout value.
    ///
    func getVaultTimeout() async throws -> SessionTimeoutValue {
        try await getVaultTimeout(userId: nil)
    }

    /// Whether the active user account is authenticated.
    ///
    /// - Returns: Whether the user is authenticated.
    ///
    func isAuthenticated() async throws -> Bool {
        try await isAuthenticated(userId: nil)
    }

    /// Logs the user out of the active account.
    ///
    /// - Parameters userInitiated: Whether the logout was user initiated or a result of a logout
    ///     timeout action.
    ///
    func logoutAccount(userInitiated: Bool) async throws {
        try await logoutAccount(userId: nil, userInitiated: userInitiated)
    }

    /// The pin protected user key.
    ///
    /// - Returns: The pin protected user key.
    ///
    func pinProtectedUserKey() async throws -> String? {
        try await pinProtectedUserKey(userId: nil)
    }

    /// The pin protected user key envelope.
    ///
    /// - Returns: The pin protected user key envelope.
    ///
    func pinProtectedUserKeyEnvelope() async throws -> String? {
        try await pinProtectedUserKeyEnvelope(userId: nil)
    }

    /// Sets the access token's expiration date for the active account.
    ///
    /// - Parameter expirationDate: The user's access token expiration date.
    ///
    func setAccessTokenExpirationDate(_ expirationDate: Date?) async throws {
        try await setAccessTokenExpirationDate(expirationDate, userId: getActiveAccountId())
    }

    /// Sets the account encryption keys for the active account.
    ///
    /// - Parameter encryptionKeys: The account encryption keys.
    ///
    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys) async throws {
        try await setAccountEncryptionKeys(encryptionKeys, userId: nil)
    }

    /// Sets whether the user has unlocked their account in the current session  interactively.
    /// - Parameter value: Whether the user has unlocked their account in the current session
    func setAccountHasBeenUnlockedInteractively(value: Bool) async throws {
        try await setAccountHasBeenUnlockedInteractively(userId: nil, value: value)
    }

    /// Sets the KDF config for the active account.
    ///
    /// - Parameter kdfConfig: The account's KDF config.
    ///
    func setAccountKdf(_ kdfConfig: KdfConfig) async throws {
        try await setAccountKdf(kdfConfig, userId: getActiveAccountId())
    }

    /// Sets the master password unlock data for the active account.
    ///
    /// - Parameter masterPasswordUnlock: The account master password unlock data.
    ///
    func setAccountMasterPasswordUnlock(_ masterPasswordUnlock: MasterPasswordUnlockResponseModel) async throws {
        let userId = try await getActiveAccountId()
        await setAccountMasterPasswordUnlock(masterPasswordUnlock, userId: userId)
    }

    /// Sets the active user's progress for setting up autofill.
    ///
    /// - Parameter autofillSetup: The user's autofill setup progress.
    ///
    func setAccountSetupAutofill(_ autofillSetup: AccountSetupProgress?) async throws {
        try await setAccountSetupAutofill(autofillSetup, userId: nil)
    }

    /// Sets the active user's progress for importing logins.
    ///
    /// - Parameter importLogins: The user's import logins progress.
    ///
    func setAccountSetupImportLogins(_ importLogins: AccountSetupProgress?) async throws {
        try await setAccountSetupImportLogins(importLogins, userId: nil)
    }

    /// Sets the active user's progress for setting up vault unlock.
    ///
    /// - Parameter vaultUnlockSetup: The user's vault unlock setup progress.
    ///
    func setAccountSetupVaultUnlock(_ vaultUnlockSetup: AccountSetupProgress?) async throws {
        try await setAccountSetupVaultUnlock(vaultUnlockSetup, userId: nil)
    }

    /// Sets the allow sync on refresh value for the active account.
    ///
    /// - Parameter allowSyncOnRefresh: The allow sync on refresh value.
    ///
    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool) async throws {
        try await setAllowSyncOnRefresh(allowSyncOnRefresh, userId: nil)
    }

    /// Sets the Universal Clipboard setting for the active account.
    ///
    /// - Parameter allowUniversalClipboard: A Boolean value indicating whether Universal Clipboard should be allowed.
    ///
    func setAllowUniversalClipboard(_ allowUniversalClipboard: Bool) async throws {
        try await setAllowUniversalClipboard(allowUniversalClipboard, userId: nil)
    }

    /// Sets the clear clipboard value for the active account.
    ///
    /// - Parameter clearClipboardValue: The time after which to clear the clipboard.
    ///
    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?) async throws {
        try await setClearClipboardValue(clearClipboardValue, userId: nil)
    }

    /// Sets the connect to watch value for the active account.
    ///
    /// - Parameter connectToWatch: Whether to connect to the watch app.
    ///
    func setConnectToWatch(_ connectToWatch: Bool) async throws {
        try await setConnectToWatch(connectToWatch, userId: nil)
    }

    /// Sets the default URI match type value the active account.
    ///
    /// - Parameter defaultUriMatchType: The default URI match type.
    ///
    func setDefaultUriMatchType(_ defaultUriMatchType: UriMatchType?) async throws {
        try await setDefaultUriMatchType(defaultUriMatchType, userId: nil)
    }

    /// Sets the disable auto-copy TOTP value for an account.
    ///
    /// - Parameter disableAutoTotpCopy: Whether the TOTP for a cipher should be auto-copied.
    ///
    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool) async throws {
        try await setDisableAutoTotpCopy(disableAutoTotpCopy, userId: nil)
    }

    /// Sets the force password reset reason for the active account.
    ///
    /// - Parameter reason: The reason why a password reset is required.
    ///
    func setForcePasswordResetReason(_ reason: ForcePasswordResetReason?) async throws {
        try await setForcePasswordResetReason(reason, userId: nil)
    }

    /// Sets whether a sync has been done successfully after login for the current user.
    /// This is particular useful to trigger logic that needs to be executed right after login in
    /// and after the first successful sync.
    ///
    /// - Parameters:
    ///   - hasBeenPerformed: Whether a sync has been performed after login.
    func setHasPerformedSyncAfterLogin(_ hasBeenPerformed: Bool) async throws {
        try await setHasPerformedSyncAfterLogin(hasBeenPerformed, userId: nil)
    }

    /// Sets the last active time within the app.
    ///
    /// - Parameter date: The current time.
    ///
    func setLastActiveTime(_ date: Date?) async throws {
        try await setLastActiveTime(date, userId: nil)
    }

    /// Sets the time of the last sync for a user ID.
    ///
    /// - Parameter date: The time of the last sync (as the number of seconds since the Unix epoch).]
    ///
    func setLastSyncTime(_ date: Date?) async throws {
        try await setLastSyncTime(date, userId: nil)
    }

    /// Sets the master password hash for the active account.
    ///
    /// - Parameter hash: The user's master password hash.
    ///
    func setMasterPasswordHash(_ hash: String?) async throws {
        try await setMasterPasswordHash(hash, userId: nil)
    }

    /// Sets the last notifications registration date for the active account.
    ///
    /// - Parameter date: The last notifications registration date.
    ///
    func setNotificationsLastRegistrationDate(_ date: Date?) async throws {
        try await setNotificationsLastRegistrationDate(date, userId: nil)
    }

    /// Sets the password generation options for the active account.
    ///
    /// - Parameter options: The user's password generation options.
    ///
    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?) async throws {
        try await setPasswordGenerationOptions(options, userId: nil)
    }

    /// Sets the app rehydration state for the active account.
    ///
    /// - Parameter rehydrationState: The app rehydration state.
    ///
    func setAppRehydrationState(_ rehydrationState: AppRehydrationState?) async throws {
        try await setAppRehydrationState(rehydrationState, userId: nil)
    }

    /// Set whether to allow access to Siri & Shortcuts using `AppIntent` for the active account.
    ///
    /// - Parameters:
    ///   - siriAndShortcutsAccess: Whether access is enabled.
    func setSiriAndShortcutsAccess(_ siriAndShortcutsAccess: Bool) async throws {
        try await setSiriAndShortcutsAccess(siriAndShortcutsAccess, userId: nil)
    }

    /// Sets the sync to authenticator value for the active account.
    ///
    /// - Parameter syncToAuthenticator: Whether to sync TOTP codes to the Authenticator app.
    ///
    func setSyncToAuthenticator(_ syncToAuthenticator: Bool) async throws {
        try await setSyncToAuthenticator(syncToAuthenticator, userId: nil)
    }

    /// Sets the session timeout action.
    ///
    /// - Parameter action: The action to take when the user's session times out.
    ///
    func setTimeoutAction(action: SessionTimeoutAction) async throws {
        try await setTimeoutAction(action: action, userId: nil)
    }

    /// Sets the number of unsuccessful attempts to unlock the vault for the active account.
    ///
    /// - Parameter attempts: The number of unsuccessful unlock attempts.
    ///
    func setUnsuccessfulUnlockAttempts(_ attempts: Int) async {
        try? await setUnsuccessfulUnlockAttempts(attempts, userId: nil)
    }

    /// Sets the username generation options for the active account.
    ///
    /// - Parameter options: The user's username generation options.
    ///
    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?) async throws {
        try await setUsernameGenerationOptions(options, userId: nil)
    }

    /// Sets whether the user uses key connector.
    ///
    /// - Parameter usesKeyConnector: Whether the user uses key connector.
    ///
    func setUsesKeyConnector(_ usesKeyConnector: Bool) async throws {
        try await setUsesKeyConnector(usesKeyConnector, userId: nil)
    }

    /// Sets the session timeout value.
    ///
    /// - Parameter value: The value that dictates how many seconds in the future a timeout should occur.
    ///
    func setVaultTimeout(value: SessionTimeoutValue) async throws {
        try await setVaultTimeout(value: value, userId: nil)
    }
}

// MARK: - StateServiceError

/// The errors thrown from a `StateService`.
///
enum StateServiceError: LocalizedError {
    /// There are no known accounts.
    case noAccounts

    /// There isn't an account with the specified user ID.
    case noAccountForUserId

    /// There isn't an active account.
    case noActiveAccount

    /// The user has no private key.
    case noEncryptedPrivateKey

    /// The user has no pin protected user key.
    case noPinProtectedUserKey

    /// The user has no user key.
    case noEncUserKey

    var errorDescription: String? {
        switch self {
        case .noActiveAccount:
            Localizations.noAccountFoundPleaseLogInAgainIfYouContinueToSeeThisError
        default:
            nil
        }
    }
}

// MARK: - DefaultStateService

/// A default implementation of `StateService`.
///
actor DefaultStateService: StateService, ActiveAccountStateProvider, ConfigStateService, FlightRecorderStateService, LanguageStateService { // swiftlint:disable:this type_body_length line_length
    // MARK: Properties

    /// The language option currently selected for the app.
    nonisolated var appLanguage: LanguageOption {
        get { LanguageOption(appSettingsStore.appLocale) }
        set { appSettingsStore.appLocale = newValue.value }
    }

    /// The organization identifier being remembered on the single-sign on screen.
    nonisolated var rememberedOrgIdentifier: String? {
        get { appSettingsStore.rememberedOrgIdentifier }
        set { appSettingsStore.rememberedOrgIdentifier = newValue }
    }

    // MARK: Private Properties

    /// The data stored in memory.
    var accountVolatileData: [String: AccountVolatileData] = [:]

    /// The service that persists app settings.
    let appSettingsStore: AppSettingsStore

    /// A subject containing the app theme.
    private var appThemeSubject: CurrentValueSubject<AppTheme, Never>

    /// A subject containing the connect to watch value.
    private var connectToWatchByUserIdSubject = CurrentValueSubject<[String: Bool], Never>([:])

    /// The data store that handles performing data requests.
    private let dataStore: DataStore

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// A subject containing the last sync time mapped to user ID.
    private var lastSyncTimeByUserIdSubject = CurrentValueSubject<[String: Date], Never>([:])

    /// A service used to access data in the keychain.
    private let keychainRepository: KeychainRepository

    /// A subject containing the pending App Intent actions.
    private var pendingAppIntentActionsSubject = CurrentValueSubject<[PendingAppIntentAction]?, Never>(nil)

    /// A subject containing the settings badge value mapped to user ID.
    private let settingsBadgeByUserIdSubject = CurrentValueSubject<[String: SettingsBadgeState], Never>([:])

    /// A subject containing whether to show the website icons.
    private var showWebIconsSubject: CurrentValueSubject<Bool, Never>

    /// A subject containing the sync to authenticator value.
    private var syncToAuthenticatorByUserIdSubject = CurrentValueSubject<[String: Bool], Never>([:])

    // MARK: Initialization

    /// Initialize a `DefaultStateService`.
    ///
    /// - Parameters:
    ///  - appSettingsStore: The service that persists app settings.
    ///  - dataStore: The data store that handles performing data requests.
    ///  - errorReporter: The service used by the application to report non-fatal errors.
    ///  - keychainRepository: A service used to access data in the keychain.
    ///
    init(
        appSettingsStore: AppSettingsStore,
        dataStore: DataStore,
        errorReporter: ErrorReporter,
        keychainRepository: KeychainRepository,
    ) {
        self.appSettingsStore = appSettingsStore
        self.dataStore = dataStore
        self.errorReporter = errorReporter
        self.keychainRepository = keychainRepository

        appThemeSubject = CurrentValueSubject(AppTheme(appSettingsStore.appTheme))
        showWebIconsSubject = CurrentValueSubject(!appSettingsStore.disableWebIcons)

        Task {
            for await activeUserId in await self.appSettingsStore.activeAccountIdPublisher().values {
                errorReporter.setUserId(activeUserId)
            }
        }
    }

    // MARK: Methods

    func addAccount(_ account: Account) async {
        var state = appSettingsStore.state ?? State()
        defer { appSettingsStore.state = state }

        state.accounts[account.profile.userId] = account
        state.activeUserId = account.profile.userId
    }

    func clearPins() async throws {
        let userId = try getActiveAccountUserId()
        accountVolatileData[userId]?.pinProtectedUserKey = nil
        appSettingsStore.setEncryptedPin(nil, userId: userId)
        appSettingsStore.setPinProtectedUserKey(key: nil, userId: userId)
        appSettingsStore.setPinProtectedUserKeyEnvelope(key: nil, userId: userId)
    }

    func deleteAccount() async throws {
        try await logoutAccount(userInitiated: true)
    }

    func didAccountSwitchInExtension() async throws -> Bool {
        do {
            return try getActiveAccountUserId() != appSettingsStore.cachedActiveUserId
        } catch StateServiceError.noActiveAccount {
            let cachedActiveUserId = appSettingsStore.cachedActiveUserId
            // If the user was logged out in the extension, but there's a cached active user,
            // reset the state to update the cached active user.
            appSettingsStore.state = appSettingsStore.state
            return cachedActiveUserId != nil
        }
    }

    func doesActiveAccountHavePremium() async -> Bool {
        do {
            let account = try await getActiveAccount()
            let hasPremiumPersonally = account.profile.hasPremiumPersonally ?? false
            guard !hasPremiumPersonally else {
                return true
            }

            let organizations = try await dataStore
                .fetchAllOrganizations(userId: account.profile.userId)
                .filter { $0.enabled && $0.usersGetPremium }
            return !organizations.isEmpty
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }

    func getAccessTokenExpirationDate(userId: String) -> Date? {
        appSettingsStore.accessTokenExpirationDate(userId: userId)
    }

    func getAccount(userId: String?) throws -> Account {
        guard let accounts = appSettingsStore.state?.accounts else {
            throw StateServiceError.noAccounts
        }
        let userId = try userId ?? getActiveAccountUserId()
        guard let account = accounts
            .first(where: { $0.value.profile.userId == userId })?.value else {
            throw StateServiceError.noAccounts
        }
        return account
    }

    func getAccountEncryptionKeys(userId: String?) async throws -> AccountEncryptionKeys {
        let userId = try userId ?? getActiveAccountUserId()
        guard let encryptedPrivateKey = appSettingsStore.encryptedPrivateKey(userId: userId) else {
            throw StateServiceError.noEncryptedPrivateKey
        }
        return AccountEncryptionKeys(
            accountKeys: appSettingsStore.accountKeys(userId: userId),
            encryptedPrivateKey: encryptedPrivateKey,
            encryptedUserKey: appSettingsStore.encryptedUserKey(userId: userId),
        )
    }

    func getAccountHasBeenUnlockedInteractively(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return accountVolatileData[userId]?.hasBeenUnlockedInteractively == true
    }

    func getAccountSetupAutofill(userId: String) async -> AccountSetupProgress? {
        appSettingsStore.accountSetupAutofill(userId: userId)
    }

    func getAccountSetupImportLogins(userId: String) async -> AccountSetupProgress? {
        appSettingsStore.accountSetupImportLogins(userId: userId)
    }

    func getAccountSetupVaultUnlock(userId: String) async -> AccountSetupProgress? {
        appSettingsStore.accountSetupVaultUnlock(userId: userId)
    }

    func getAccounts() throws -> [Account] {
        guard let accounts = appSettingsStore.state?.accounts else {
            throw StateServiceError.noAccounts
        }
        return Array(accounts.values)
    }

    func getActiveAccount() throws -> Account {
        guard let activeAccount = appSettingsStore.state?.activeAccount else {
            throw StateServiceError.noActiveAccount
        }
        return activeAccount
    }

    func getAddSitePromptShown() async -> Bool {
        appSettingsStore.addSitePromptShown
    }

    func getAllowSyncOnRefresh(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.allowSyncOnRefresh(userId: userId)
    }

    func getAllowUniversalClipboard(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.allowUniversalClipboard(userId: userId)
    }

    func getAppRehydrationState(userId: String?) async throws -> AppRehydrationState? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.appRehydrationState(userId: userId)
    }

    func getAppTheme() async -> AppTheme {
        AppTheme(appSettingsStore.appTheme)
    }

    func getClearClipboardValue(userId: String?) async throws -> ClearClipboardValue {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.clearClipboardValue(userId: userId)
    }

    func getConnectToWatch(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.connectToWatch(userId: userId)
    }

    func getDefaultUriMatchType(userId: String?) async -> UriMatchType {
        do {
            let userId = try userId ?? getActiveAccountUserId()
            return appSettingsStore.defaultUriMatchType(userId: userId) ?? .domain
        } catch {
            errorReporter.log(error: error)
            return .domain
        }
    }

    func getDisableAutoTotpCopy(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.disableAutoTotpCopy(userId: userId)
    }

    func getEncryptedPin(userId: String?) async throws -> String? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.encryptedPin(userId: userId)
    }

    func getEnvironmentURLs(userId: String?) async throws -> EnvironmentURLData? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.state?.accounts[userId]?.settings.environmentUrls
    }

    func getEvents(userId: String?) async throws -> [EventData] {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.events(userId: userId)
    }

    func getFlightRecorderData() async -> FlightRecorderData? {
        appSettingsStore.flightRecorderData
    }

    func getHasPerformedSyncAfterLogin(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.hasPerformedSyncAfterLogin(userId: userId)
    }

    func getIntroCarouselShown() async -> Bool {
        appSettingsStore.introCarouselShown
    }

    func getLastActiveTime(userId: String?) async throws -> Date? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.lastActiveTime(userId: userId)
    }

    func getLastSyncTime(userId: String?) async throws -> Date? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.lastSyncTime(userId: userId)
    }

    func getLastUserShouldConnectToWatch() async -> Bool {
        appSettingsStore.lastUserShouldConnectToWatch
    }

    func getLoginRequest() async -> LoginRequestNotification? {
        appSettingsStore.loginRequest
    }

    func getManuallyLockedAccount(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.manuallyLockedAccount(userId: userId)
    }

    func getMasterPasswordHash(userId: String?) async throws -> String? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.masterPasswordHash(userId: userId)
    }

    func getNotificationsLastRegistrationDate(userId: String?) async throws -> Date? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.notificationsLastRegistrationDate(userId: userId)
    }

    func getPasswordGenerationOptions(userId: String?) async throws -> PasswordGenerationOptions? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.passwordGenerationOptions(userId: userId)
    }

    func getPendingAppIntentActions() async -> [PendingAppIntentAction]? {
        appSettingsStore.pendingAppIntentActions
    }

    func getPreAuthEnvironmentURLs() async -> EnvironmentURLData? {
        appSettingsStore.preAuthEnvironmentURLs
    }

    func getAccountCreationEnvironmentURLs(email: String) async -> EnvironmentURLData? {
        appSettingsStore.accountCreationEnvironmentURLs(email: email)
    }

    func getLearnGeneratorActionCardStatus() async -> AccountSetupProgress? {
        appSettingsStore.learnGeneratorActionCardStatus
    }

    func getPreAuthServerConfig() async -> ServerConfig? {
        appSettingsStore.preAuthServerConfig
    }

    func getReviewPromptData() async -> ReviewPromptData? {
        appSettingsStore.reviewPromptData
    }

    func getServerConfig(userId: String?) async throws -> ServerConfig? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.serverConfig(userId: userId)
    }

    func getShouldTrustDevice(userId: String) async -> Bool? {
        appSettingsStore.shouldTrustDevice(userId: userId)
    }

    func getLearnNewLoginActionCardStatus() async -> AccountSetupProgress? {
        appSettingsStore.learnNewLoginActionCardStatus
    }

    func getShowWebIcons() async -> Bool {
        !appSettingsStore.disableWebIcons
    }

    func getSiriAndShortcutsAccess(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.siriAndShortcutsAccess(userId: userId)
    }

    func getSyncToAuthenticator(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.syncToAuthenticator(userId: userId)
    }

    func getTimeoutAction(userId: String?) async throws -> SessionTimeoutAction {
        let userId = try userId ?? getActiveAccountUserId()
        guard let rawValue = appSettingsStore.timeoutAction(userId: userId),
              let timeoutAction = SessionTimeoutAction(rawValue: rawValue) else {
            return .lock
        }
        return timeoutAction
    }

    func getTwoFactorToken(email: String) async -> String? {
        appSettingsStore.twoFactorToken(email: email)
    }

    func getUnsuccessfulUnlockAttempts(userId: String?) async throws -> Int {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.unsuccessfulUnlockAttempts(userId: userId)
    }

    func getUserHasMasterPassword(userId: String?) async throws -> Bool {
        try getAccount(userId: userId).profile.userDecryptionOptions?.hasMasterPassword ?? true
    }

    func getUserIds(email: String) async -> [String] {
        guard let state = appSettingsStore.state else { return [] }
        let userIds = state.accounts.values.filter { $0.profile.email == email }.map(\.profile.userId)
        return userIds
    }

    func getUsernameGenerationOptions(userId: String?) async throws -> UsernameGenerationOptions? {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.usernameGenerationOptions(userId: userId)
    }

    func getUsesKeyConnector(userId: String?) async throws -> Bool {
        let userId = try userId ?? getActiveAccountUserId()
        return appSettingsStore.usesKeyConnector(userId: userId)
    }

    func getVaultTimeout(userId: String?) async throws -> SessionTimeoutValue {
        let userId = try getAccount(userId: userId).profile.userId
        let userAuthKey = try? await keychainRepository.getUserAuthKeyValue(for: .neverLock(userId: userId))
        guard let rawValue = appSettingsStore.vaultTimeout(userId: userId) else {
            // If there isn't a stored value, it may be because MAUI stored `nil` for never timeout.
            // So if the never lock key exists, set the timeout to never, otherwise to default.
            return userAuthKey != nil ? .never : .fifteenMinutes
        }

        let timeoutValue = SessionTimeoutValue(rawValue: rawValue)
        if timeoutValue == .never, userAuthKey == nil {
            // If never lock but no key (possibly due to logging out), return the default timeout.
            return .fifteenMinutes
        }
        return timeoutValue
    }

    func isAuthenticated(userId: String?) async throws -> Bool {
        do {
            let userId = try getAccount(userId: userId).profile.userId
            _ = try await keychainRepository.getAccessToken(userId: userId)
            return true
        } catch StateServiceError.noActiveAccount {
            return false
        } catch StateServiceError.noAccounts {
            return false
        } catch KeychainServiceError.osStatusError(errSecItemNotFound) {
            return false
        }
    }

    func logoutAccount(userId: String?, userInitiated: Bool) async throws {
        guard var state = appSettingsStore.state else { return }
        defer { appSettingsStore.state = state }

        let knownUserId: String = try userId ?? getActiveAccountUserId()
        if userInitiated {
            state.accounts.removeValue(forKey: knownUserId)
        }
        if state.activeUserId == knownUserId, userInitiated {
            // Find the next account to make the active account.
            state.activeUserId = state.accounts.first?.key
        }

        appSettingsStore.setAccessTokenExpirationDate(nil, userId: knownUserId)
        appSettingsStore.setBiometricAuthenticationEnabled(nil, for: knownUserId)
        appSettingsStore.setDefaultUriMatchType(nil, userId: knownUserId)
        appSettingsStore.setDisableAutoTotpCopy(nil, userId: knownUserId)
        appSettingsStore.setAccountKeys(nil, userId: knownUserId)
        appSettingsStore.setEncryptedPrivateKey(key: nil, userId: knownUserId)
        appSettingsStore.setEncryptedUserKey(key: nil, userId: knownUserId)
        appSettingsStore.setHasPerformedSyncAfterLogin(nil, userId: knownUserId)
        appSettingsStore.setLastSyncTime(nil, userId: knownUserId)
        appSettingsStore.setMasterPasswordHash(nil, userId: knownUserId)
        appSettingsStore.setPasswordGenerationOptions(nil, userId: knownUserId)

        try await dataStore.deleteDataForUser(userId: knownUserId)
    }

    func pinProtectedUserKey(userId: String?) async throws -> String? {
        let userId = try userId ?? getActiveAccountUserId()
        return accountVolatileData[userId]?.pinProtectedUserKey ?? appSettingsStore.pinProtectedUserKey(userId: userId)
    }

    func pinProtectedUserKeyEnvelope(userId: String?) async throws -> String? {
        let userId = try userId ?? getActiveAccountUserId()
        let key = accountVolatileData[userId]?.pinProtectedUserKey
            ?? appSettingsStore.pinProtectedUserKeyEnvelope(userId: userId)
        return key
    }

    func pinUnlockRequiresPasswordAfterRestart() async throws -> Bool {
        let userId = try getActiveAccountUserId()
        return appSettingsStore.pinProtectedUserKeyEnvelope(userId: userId) == nil
            && appSettingsStore.pinProtectedUserKey(userId: userId) == nil
    }

    func setAccessTokenExpirationDate(_ expirationDate: Date?, userId: String) async {
        appSettingsStore.setAccessTokenExpirationDate(expirationDate, userId: userId)
    }

    func setAccountKdf(_ kdfConfig: KdfConfig, userId: String) async throws {
        try updateAccountProfile(userId: userId) { profile in
            profile.kdfType = kdfConfig.kdfType
            profile.kdfIterations = kdfConfig.iterations
            profile.kdfMemory = kdfConfig.memory
            profile.kdfParallelism = kdfConfig.parallelism
        }
    }

    func setAccountEncryptionKeys(_ encryptionKeys: AccountEncryptionKeys, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setAccountKeys(encryptionKeys.accountKeys, userId: userId)
        appSettingsStore.setEncryptedPrivateKey(key: encryptionKeys.encryptedPrivateKey, userId: userId)
        appSettingsStore.setEncryptedUserKey(key: encryptionKeys.encryptedUserKey, userId: userId)
    }

    func setAccountHasBeenUnlockedInteractively(userId: String?, value: Bool) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        accountVolatileData[
            userId,
            default: AccountVolatileData(),
        ].hasBeenUnlockedInteractively = value
    }

    func setAccountMasterPasswordUnlock(
        _ masterPasswordUnlock: MasterPasswordUnlockResponseModel,
        userId: String,
    ) async {
        guard var state = appSettingsStore.state,
              var profile = state.accounts[userId]?.profile
        else {
            return
        }
        var userDecryptionOptions = profile.userDecryptionOptions
            ?? UserDecryptionOptions(
                hasMasterPassword: true,
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            )
        userDecryptionOptions.masterPasswordUnlock = masterPasswordUnlock
        profile.userDecryptionOptions = userDecryptionOptions
        state.accounts[userId]?.profile = profile
        appSettingsStore.state = state
    }

    func setAccountSetupAutofill(_ autofillSetup: AccountSetupProgress?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setAccountSetupAutofill(autofillSetup, userId: userId)
        await updateSettingsBadgePublisher(userId: userId)
    }

    func setAccountSetupImportLogins(_ importLogins: AccountSetupProgress?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setAccountSetupImportLogins(importLogins, userId: userId)
        await updateSettingsBadgePublisher(userId: userId)
    }

    func setAccountSetupVaultUnlock(_ vaultUnlockSetup: AccountSetupProgress?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setAccountSetupVaultUnlock(vaultUnlockSetup, userId: userId)
        await updateSettingsBadgePublisher(userId: userId)
    }

    func setActiveAccount(userId: String) async throws {
        guard var state = appSettingsStore.state else { return }
        defer { appSettingsStore.state = state }

        guard state.accounts.contains(where: { $0.key == userId }) else {
            throw StateServiceError.noAccounts
        }
        state.activeUserId = userId
    }

    func setAddSitePromptShown(_ shown: Bool) async {
        appSettingsStore.addSitePromptShown = shown
    }

    func setAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setAllowSyncOnRefresh(allowSyncOnRefresh, userId: userId)
    }

    func setAllowUniversalClipboard(_ allowUniversalClipboard: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setAllowUniversalClipboard(allowUniversalClipboard, userId: userId)
    }

    func setAppTheme(_ appTheme: AppTheme) async {
        appSettingsStore.appTheme = appTheme.value
        appThemeSubject.send(appTheme)
    }

    func setClearClipboardValue(_ clearClipboardValue: ClearClipboardValue?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setClearClipboardValue(clearClipboardValue, userId: userId)
    }

    func setConnectToWatch(_ connectToWatch: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setConnectToWatch(connectToWatch, userId: userId)
        connectToWatchByUserIdSubject.value[userId] = connectToWatch

        // Save the value of the connect to watch setting independent of the user id,
        // in order to be able to send a status to the watch if the user logs out.
        appSettingsStore.lastUserShouldConnectToWatch = connectToWatch
    }

    func setDefaultUriMatchType(_ defaultUriMatchType: UriMatchType?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setDefaultUriMatchType(defaultUriMatchType, userId: userId)
    }

    func setDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setDisableAutoTotpCopy(disableAutoTotpCopy, userId: userId)
    }

    func setEvents(_ events: [EventData], userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setEvents(events, userId: userId)
    }

    func setFlightRecorderData(_ data: FlightRecorderData?) async {
        appSettingsStore.flightRecorderData = data
    }

    func setForcePasswordResetReason(_ reason: ForcePasswordResetReason?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        guard var state = appSettingsStore.state else {
            throw StateServiceError.noAccounts
        }
        defer { appSettingsStore.state = state }
        state.accounts[userId]?.profile.forcePasswordResetReason = reason
    }

    func setHasPerformedSyncAfterLogin(_ hasBeenPerformed: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setHasPerformedSyncAfterLogin(hasBeenPerformed, userId: userId)
    }

    func setIntroCarouselShown(_ shown: Bool) async {
        appSettingsStore.introCarouselShown = shown
    }

    func setLearnNewLoginActionCardStatus(_ status: AccountSetupProgress) async {
        appSettingsStore.learnNewLoginActionCardStatus = status
    }

    func setLastActiveTime(_ date: Date?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setLastActiveTime(date, userId: userId)
    }

    func setLastSyncTime(_ date: Date?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setLastSyncTime(date, userId: userId)
        lastSyncTimeByUserIdSubject.value[userId] = date
    }

    func setLearnGeneratorActionCardStatus(_ status: AccountSetupProgress) async {
        appSettingsStore.learnGeneratorActionCardStatus = status
    }

    func setLoginRequest(_ loginRequest: LoginRequestNotification?) async {
        appSettingsStore.loginRequest = loginRequest
    }

    func setManuallyLockedAccount(_ isLocked: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setManuallyLockedAccount(isLocked, userId: userId)
    }

    func setMasterPasswordHash(_ hash: String?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setMasterPasswordHash(hash, userId: userId)
    }

    func setNotificationsLastRegistrationDate(_ date: Date?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setNotificationsLastRegistrationDate(date, userId: userId)
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setPasswordGenerationOptions(options, userId: userId)
    }

    func setPendingAppIntentActions(actions: [PendingAppIntentAction]?) async {
        guard !actions.isEmptyOrNil else {
            appSettingsStore.pendingAppIntentActions = nil
            pendingAppIntentActionsSubject.send(nil)
            return
        }

        appSettingsStore.pendingAppIntentActions = actions
        pendingAppIntentActionsSubject.send(actions)
    }

    func setPinKeys(
        enrollPinResponse: EnrollPinResponse,
        requirePasswordAfterRestart: Bool,
    ) async throws {
        let userId = try getActiveAccountUserId()
        if requirePasswordAfterRestart {
            try await setPinProtectedUserKeyToMemory(enrollPinResponse.pinProtectedUserKeyEnvelope)
        } else {
            appSettingsStore.setPinProtectedUserKeyEnvelope(
                key: enrollPinResponse.pinProtectedUserKeyEnvelope,
                userId: userId,
            )
        }
        appSettingsStore.setEncryptedPin(enrollPinResponse.userKeyEncryptedPin, userId: userId)

        // Remove any legacy pin protected user keys.
        appSettingsStore.setPinProtectedUserKey(key: nil, userId: userId)
    }

    func setPinProtectedUserKeyToMemory(_ pinProtectedUserKey: String) async throws {
        try accountVolatileData[
            getActiveAccountUserId(),
            default: AccountVolatileData(),
        ].pinProtectedUserKey = pinProtectedUserKey
    }

    func setPreAuthEnvironmentURLs(_ urls: EnvironmentURLData) async {
        appSettingsStore.preAuthEnvironmentURLs = urls
    }

    func setAccountCreationEnvironmentURLs(urls: EnvironmentURLData, email: String) async {
        appSettingsStore.setAccountCreationEnvironmentURLs(
            environmentURLData: urls,
            email: email,
        )
    }

    func setPreAuthServerConfig(config: ServerConfig) async {
        appSettingsStore.preAuthServerConfig = config
    }

    func setAppRehydrationState(_ rehydrationState: AppRehydrationState?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setAppRehydrationState(rehydrationState, userId: userId)
    }

    func setReviewPromptData(_ data: ReviewPromptData) async {
        appSettingsStore.reviewPromptData = data
    }

    func setServerConfig(_ config: ServerConfig?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setServerConfig(config, userId: userId)
    }

    func setShouldTrustDevice(_ shouldTrustDevice: Bool?, userId: String) {
        appSettingsStore.setShouldTrustDevice(shouldTrustDevice: shouldTrustDevice, userId: userId)
    }

    func setShowWebIcons(_ showWebIcons: Bool) async {
        appSettingsStore.disableWebIcons = !showWebIcons
        showWebIconsSubject.send(showWebIcons)
    }

    func setSiriAndShortcutsAccess(_ siriAndShortcutsAccess: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setSiriAndShortcutsAccess(siriAndShortcutsAccess, userId: userId)
    }

    func setSyncToAuthenticator(_ syncToAuthenticator: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setSyncToAuthenticator(syncToAuthenticator, userId: userId)
        syncToAuthenticatorByUserIdSubject.value[userId] = syncToAuthenticator
    }

    func setTimeoutAction(action: SessionTimeoutAction, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setTimeoutAction(key: action, userId: userId)
    }

    func setTwoFactorToken(_ token: String?, email: String) async {
        appSettingsStore.setTwoFactorToken(token, email: email)
    }

    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setUnsuccessfulUnlockAttempts(attempts, userId: userId)
    }

    func setUserHasMasterPassword(_ hasMasterPassword: Bool) async throws {
        let userId = try getActiveAccountUserId()
        var state = appSettingsStore.state ?? State()
        defer { appSettingsStore.state = state }

        guard var profile = state.accounts[userId]?.profile else { return }
        profile.userDecryptionOptions?.hasMasterPassword = hasMasterPassword

        state.accounts[userId]?.profile = profile
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions?, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setUsernameGenerationOptions(options, userId: userId)
    }

    func setUsesKeyConnector(_ usesKeyConnector: Bool, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setUsesKeyConnector(usesKeyConnector, userId: userId)
    }

    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws {
        let userId = try userId ?? getActiveAccountUserId()
        appSettingsStore.setVaultTimeout(minutes: value.rawValue, userId: userId)
    }

    func updateProfile(from response: ProfileResponseModel, userId: String) async {
        var state = appSettingsStore.state ?? State()
        defer { appSettingsStore.state = state }

        guard var profile = state.accounts[userId]?.profile else { return }
        profile.hasPremiumPersonally = response.premium
        profile.avatarColor = response.avatarColor
        profile.creationDate = response.creationDate
        profile.email = response.email ?? profile.email
        profile.emailVerified = response.emailVerified
        profile.name = response.name
        profile.stamp = response.securityStamp
        profile.twoFactorEnabled = response.twoFactorEnabled

        state.accounts[userId]?.profile = profile
    }

    // MARK: Publishers

    func activeAccountIdPublisher() -> AnyPublisher<String?, Never> {
        appSettingsStore.activeAccountIdPublisher()
    }

    func appThemePublisher() async -> AnyPublisher<AppTheme, Never> {
        appThemeSubject.eraseToAnyPublisher()
    }

    func connectToWatchPublisher() async -> AnyPublisher<(String?, Bool), Never> {
        activeAccountIdPublisher().flatMap { userId in
            self.connectToWatchByUserIdSubject.map { values in
                let userValue = if let userId {
                    // Get the user's setting, if they're logged in.
                    values[userId] ?? self.appSettingsStore.connectToWatch(userId: userId)
                } else {
                    // Otherwise, use the last known value for the previous user.
                    self.appSettingsStore.lastUserShouldConnectToWatch
                }
                return (userId, userValue)
            }
        }
        .eraseToAnyPublisher()
    }

    func lastSyncTimePublisher() async throws -> AnyPublisher<Date?, Never> {
        let userId = try getActiveAccountUserId()
        if lastSyncTimeByUserIdSubject.value[userId] == nil {
            lastSyncTimeByUserIdSubject.value[userId] = appSettingsStore.lastSyncTime(userId: userId)
        }
        return lastSyncTimeByUserIdSubject.map { $0[userId] }.eraseToAnyPublisher()
    }

    func pendingAppIntentActionsPublisher() async -> AnyPublisher<[PendingAppIntentAction]?, Never> {
        if pendingAppIntentActionsSubject.value == nil {
            pendingAppIntentActionsSubject.value = appSettingsStore.pendingAppIntentActions
        }
        return pendingAppIntentActionsSubject.eraseToAnyPublisher()
    }

    func settingsBadgePublisher() async throws -> AnyPublisher<SettingsBadgeState, Never> {
        let userId = try getActiveAccountUserId()
        await updateSettingsBadgePublisher(userId: userId)
        return settingsBadgeByUserIdSubject.compactMap { $0[userId] }.eraseToAnyPublisher()
    }

    func showWebIconsPublisher() async -> AnyPublisher<Bool, Never> {
        showWebIconsSubject.eraseToAnyPublisher()
    }

    func syncToAuthenticatorPublisher() async -> AnyPublisher<(String?, Bool), Never> {
        activeAccountIdPublisher().flatMap { userId in
            self.syncToAuthenticatorByUserIdSubject.map { values in
                guard let userId else {
                    return (nil, false)
                }
                let userValue = values[userId] ?? self.appSettingsStore.syncToAuthenticator(userId: userId)
                return (userId, userValue)
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: Private

    /// Returns the user ID for the active account.
    ///
    /// - Returns: The user ID for the active account.
    ///
    private func getActiveAccountUserId() throws -> String {
        guard let activeUserId = appSettingsStore.state?.activeUserId else {
            throw StateServiceError.noActiveAccount
        }
        return activeUserId
    }

    /// Updates the account's profile.
    ///
    /// - Parameters:
    ///   - userId: The user ID of the account to update.
    ///   - updateProfile: A closure that allows making updates to the account's profile. Any
    ///     updates made to the profile will be saved when the closure returns.
    ///
    private func updateAccountProfile(userId: String, updateProfile: (inout Account.AccountProfile) -> Void) throws {
        guard var state = appSettingsStore.state else { throw StateServiceError.noAccounts }
        guard var profile = state.accounts[userId]?.profile else { throw StateServiceError.noAccountForUserId }
        updateProfile(&profile)
        state.accounts[userId]?.profile = profile
        appSettingsStore.state = state
    }

    /// Updates the settings badge publisher by determining the settings badge count for the user.
    ///
    /// - Parameter userId: The user ID whose settings badge count should be updated.
    ///
    private func updateSettingsBadgePublisher(userId: String) async {
        let autofillSetupProgress = await getAccountSetupAutofill(userId: userId)
        let importLoginsSetupProgress = await getAccountSetupImportLogins(userId: userId)
        let vaultUnlockSetupProgress = await getAccountSetupVaultUnlock(userId: userId)
        var badgeCount = [autofillSetupProgress, vaultUnlockSetupProgress]
            .compactMap(\.self)
            .count(where: { $0 != .complete })

        if importLoginsSetupProgress == .setUpLater {
            badgeCount += 1
        }
        settingsBadgeByUserIdSubject.value[userId] = SettingsBadgeState(
            autofillSetupProgress: autofillSetupProgress,
            badgeValue: badgeCount > 0 ? String(badgeCount) : nil,
            importLoginsSetupProgress: importLoginsSetupProgress,
            vaultUnlockSetupProgress: vaultUnlockSetupProgress,
        )
    }
}

// MARK: - AccountVolatileData

/// The data stored in memory.
///
struct AccountVolatileData {
    /// The pin protected user key.
    var pinProtectedUserKey: String?

    /// Whether the account has been unlocked with user interaction.
    var hasBeenUnlockedInteractively = false
}

// MARK: Biometrics

extension DefaultStateService {
    func getBiometricAuthenticationEnabled() async throws -> Bool {
        let userId = try getActiveAccountUserId()
        return appSettingsStore.isBiometricAuthenticationEnabled(userId: userId)
    }

    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?) async throws {
        let userId = try getActiveAccountUserId()
        appSettingsStore.setBiometricAuthenticationEnabled(isEnabled, for: userId)
    }
}
