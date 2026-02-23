import BitwardenKit
import BitwardenSdk
import Foundation
import LocalAuthentication
import OSLog
import SwiftUI

// swiftlint:disable file_length

/// A protocol for an `AuthRepository` which manages access to the data needed by the UI layer.
///
protocol AuthRepository: AnyObject {
    // MARK: Methods

    /// Enables or disables biometric unlock for the active user.
    ///
    /// - Parameters:
    ///   - enabled: Whether or not the the user wants biometric auth enabled.
    ///     If `true`, the userAuthKey is stored to the keychain and the user preference is set to false.
    ///     If `false`, any userAuthKey is deleted from the keychain and the user preference is set to false.
    ///
    func allowBioMetricUnlock(_ enabled: Bool) async throws

    /// Whether a user account can be locked.
    ///
    /// - Parameter userId: The user Id to be mapped to an account.
    /// - Returns: `true` if the account can be locked, `false` otherwise.
    ///
    func canBeLocked(userId: String?) async -> Bool

    /// Whether master password verification can be done for a userId.
    ///
    /// - Parameter userId:  The user Id to be mapped to an account.
    /// - Returns: `true` if one can verify master password, `false` otherwise.
    ///
    func canVerifyMasterPassword(userId: String?) async throws -> Bool

    /// Checks the session timeout for all accounts, and locks or logs out as needed.
    ///
    /// - Parameters:
    ///   - isAppRestart: Whether the app has been restarted and is checking timeouts on app
    ///     startup. Defaults to false.
    ///   - handleActiveUser: A closure to handle the active user.
    ///
    func checkSessionTimeouts(isAppRestart: Bool, handleActiveUser: ((String) async -> Void)?) async

    /// Clears the pins stored on device and in memory.
    ///
    func clearPins() async throws

    /// Convert new user to key connector.
    ///
    func convertNewUserToKeyConnector(keyConnectorURL: URL, orgIdentifier: String) async throws

    /// Create new account for a JIT sso user .
    ///
    func createNewSsoUser(orgIdentifier: String, rememberDevice: Bool) async throws

    /// Deletes the user's account.
    ///
    /// - Parameters:
    ///   - otp: The user's one-time password, if they don't have a master password.
    ///   - passwordText: The password entered by the user, which is used to verify
    ///     their identify before deleting the account.
    ///
    func deleteAccount(otp: String?, passwordText: String?) async throws

    /// Returns the user ID of an existing account that is already logged in on the device matching
    /// the specified email.
    ///
    /// - Parameter email: The email for the account to check.
    /// - Returns: The user ID of the account that is already logged in on the device, or `nil` otherwise.
    ///
    func existingAccountUserId(email: String) async -> String?

    /// Gets the account for a user id.
    ///
    /// - Parameter userId: The user Id to be mapped to an account.
    /// - Returns: The user account.
    ///
    func getAccount(for userId: String?) async throws -> Account

    /// Gets the current account's unique fingerprint phrase.
    ///
    /// - Returns: The account fingerprint phrase.
    ///
    func getFingerprintPhrase() async throws -> String

    /// Gets the organization identifier by email for the single sign on process.
    /// - Parameter email: The email to get the organization identifier.
    /// - Returns: The organization identifier, if any that complies with verified domains. Also `nil` if empty.
    func getSingleSignOnOrganizationIdentifier(email: String) async throws -> String?

    /// Check if the user has a master password
    ///
    func hasMasterPassword() async throws -> Bool

    /// Checks the locked status of a user vault by user id.
    ///
    ///  - Parameter userId: The userId of the account.
    ///  - Returns: Returns: `True` if locked, `false` otherwise.
    ///
    func isLocked(userId: String?) async throws -> Bool

    /// Whether pin unlock is available for a userId.
    ///  - Parameter userId: The userId of the account.
    ///  - Returns: Whether pin unlock is available.
    ///
    func isPinUnlockAvailable(userId: String?) async throws -> Bool

    /// Whether the user is managed by an organization.
    ///
    /// - Returns: `true` user is managed by an organization, `false` otherwise.
    ///
    func isUserManagedByOrganization() async throws -> Bool

    /// User leaves organization
    ///
    /// - Parameters:
    ///   - organizationId: The ID of the organization the user is leaving.
    func leaveOrganization(organizationId: String) async throws

    /// Locks all vaults and clears decrypted data from memory
    /// - Parameter isManuallyLocking: Whether the user is manually locking the account.
    ///
    func lockAllVaults(isManuallyLocking: Bool) async throws

    /// Locks the user's vault and clears decrypted data from memory
    /// - Parameters:
    ///   - userId: The userId of the account to lock. Defaults to active account if nil
    ///   - isManuallyLocking: Whether the user is manually locking the account.
    ///
    func lockVault(userId: String?, isManuallyLocking: Bool) async

    /// Logs the user out of the specified account.
    ///
    /// - Parameters
    ///   - userId: The user ID of the account to log out of.
    ///   - userInitiated: Whether the logout was user initiated or a result of a logout timeout action.
    ///
    func logout(userId: String?, userInitiated: Bool) async throws

    /// Migrates the user to Key Connector if a migration is required.
    ///
    /// - Parameter password: The user's master password.
    ///
    func migrateUserToKeyConnector(password: String) async throws

    /// Calculates the password strength of a password.
    ///
    /// - Parameters:
    ///   - email: The user's email.
    ///   - password: The user's password.
    ///   - isPreAuth: Whether the client is being used for a user prior to authentication (when
    ///     the user's ID doesn't yet exist).
    /// - Returns: The password strength of the password.
    ///
    func passwordStrength(email: String, password: String, isPreAuth: Bool) async throws -> UInt8

    /// Gets the profiles state for a user.
    ///
    /// - Parameters:
    ///   - allowLockAndLogout: Should the view allow lock & logout?
    ///   - isVisible: Should the state be visible?
    ///   - shouldAlwaysHideAddAccount: Should the state always hide add account?
    ///   - showPlaceholderToolbarIcon: Should the handler replace the toolbar icon with two dots?
    /// - Returns: A ProfileSwitcherState.
    ///
    func getProfilesState(
        allowLockAndLogout: Bool,
        isVisible: Bool,
        shouldAlwaysHideAddAccount: Bool,
        showPlaceholderToolbarIcon: Bool,
    ) async -> ProfileSwitcherState

    /// Requests a one-time password to be sent to the user.
    ///
    func requestOtp() async throws

    /// Revokes the current user's access to an organization.
    ///
    /// - Parameters:
    ///   - organizationId: The ID of the organization the user is revoking access from.
    ///
    func revokeSelfFromOrganization(organizationId: String) async throws

    /// Gets the `SessionTimeoutAction` for a user.
    ///
    ///  - Parameter userId: The userId of the account. Defaults to the active user if nil.
    ///
    func sessionTimeoutAction(userId: String?) async throws -> SessionTimeoutAction

    /// Gets the `SessionTimeoutValue` for a user.
    ///
    ///  - Parameter userId: The userId of the account.
    ///     Defaults to the active user if nil.
    ///
    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue

    /// Sets the encrypted pin and the pin protected user key.
    ///
    /// - Parameters:
    ///   - pin: The user's pin.
    ///   - requirePasswordAfterRestart: Whether to require the password after an app restart.
    ///
    func setPins(_ pin: String, requirePasswordAfterRestart: Bool) async throws

    /// Sets the active account by User Id.
    ///
    /// - Parameter userId: The user Id to be set as active.
    /// - Returns: The new active account.
    ///
    func setActiveAccount(userId: String) async throws -> Account

    /// Sets the user's master password.
    ///
    /// - Parameters:
    ///   - password: The user's master password.
    ///   - masterPasswordHint: The user's password hint.
    ///   - organizationId: The ID of the organization the user is joining.
    ///   - organizationIdentifier: The shorthand organization identifier for the organization.
    ///   - resetPasswordAutoEnroll: Whether to enroll the user in reset password.
    ///
    func setMasterPassword(
        _ password: String,
        masterPasswordHint: String,
        organizationId: String,
        organizationIdentifier: String,
        resetPasswordAutoEnroll: Bool,
    ) async throws

    /// Sets the SessionTimeoutValue.
    ///
    /// - Parameters:
    ///   - newValue: The timeout value.
    ///   - userId: The user's ID.
    ///
    func setVaultTimeout(value newValue: SessionTimeoutValue, userId: String?) async throws

    /// Attempts to unlock the user's vault using information returned from the login with device method.
    ///
    /// - Parameters:
    ///   - privateKey: The private key from the login with device response.
    ///   - key: The returned key from the approved auth request.
    ///   - masterPasswordHash: The master password hash from the approved auth request.
    ///
    func unlockVaultFromLoginWithDevice(privateKey: String, key: String, masterPasswordHash: String?) async throws

    /// Attempts to unlock the user's vault with biometrics.
    ///
    func unlockVaultWithBiometrics() async throws

    /// Attempts to unlock the user's vault with the stored device key.
    ///
    func unlockVaultWithDeviceKey() async throws

    /// Attempts to unlock the user's vault with the user's Key Connector key.
    ///
    /// - Parameters:
    ///   - keyConnectorUrl: The URL to the Key Connector API.
    ///   - orgIdentifier: The text identifier for the organization.
    ///
    func unlockVaultWithKeyConnectorKey(keyConnectorURL: URL, orgIdentifier: String) async throws

    /// Attempts to unlock the user's vault with the stored neverlock key.
    ///
    func unlockVaultWithNeverlockKey() async throws

    /// Attempts to unlock the user's vault with their master password.
    ///
    /// - Parameter password: The user's master password to unlock the vault.
    ///
    func unlockVaultWithPassword(password: String) async throws

    /// Unlocks the vault using the PIN.
    ///
    /// - Parameter pin: The user's PIN.
    ///
    func unlockVaultWithPIN(pin: String) async throws

    /// Updates the user's master password.
    ///
    /// - Parameters:
    ///   - currentPassword: The user's current master password.
    ///   - newPassword: The user's new master password.
    ///   - passwordHint: The user's new password hint.
    ///   - reason: The update password reason.
    ///
    func updateMasterPassword(
        currentPassword: String,
        newPassword: String,
        passwordHint: String,
        reason: ForcePasswordResetReason,
    ) async throws

    /// Validates the user's entered master password to determine if it matches the stored hash.
    ///
    /// - Parameter password: The user's master password.
    /// - Returns: Whether the hash of the password matches the stored hash.
    ///
    func validatePassword(_ password: String) async throws -> Bool

    /// Validates the user's entered PIN.
    /// - Parameter pin: Pin to validate.
    /// - Returns: `true` if valid, `false` otherwise.
    func validatePin(pin: String) async throws -> Bool

    /// Verifies that the entered one-time password matches the one sent to the user.
    ///
    /// - Parameter otp: The user's one-time password to verify.
    ///
    func verifyOtp(_ otp: String) async throws
}

extension AuthRepository {
    /// Checks the session timeout for all accounts, and locks or logs out as needed.
    ///
    /// - Parameter handleActiveUser: A closure to handle the active user.
    ///
    func checkSessionTimeouts(handleActiveUser: ((String) async -> Void)?) async {
        await checkSessionTimeouts(isAppRestart: false, handleActiveUser: handleActiveUser)
    }

    /// Whether active user account can be locked.
    ///
    /// - Returns: `true` if active user account can be locked, `false` otherwise.
    ///
    func canBeLocked() async -> Bool {
        await canBeLocked(userId: nil)
    }

    /// Whether master password verification can be done for the active user.
    ///
    /// - Returns: `true` if active user has master password, `false` otherwise.
    func canVerifyMasterPassword() async throws -> Bool {
        try await canVerifyMasterPassword(userId: nil)
    }

    /// Gets the account for the active user id.
    ///
    /// - Returns: The active user account.
    ///
    func getAccount() async throws -> Account {
        try await getAccount(for: nil)
    }

    /// Gets the active user id.
    ///
    /// - Returns: The active user id.
    ///
    func getUserId() async throws -> String {
        try await getAccount(for: nil).profile.userId
    }

    /// Checks the locked status of a user vault by user id
    ///
    ///  - Returns: A bool, true if locked, false if unlocked.
    ///
    func isLocked() async throws -> Bool {
        try await isLocked(userId: nil)
    }

    /// Whether pin unlock is available for the active user.
    ///
    /// - Returns: `true` if pin unlock is available, `false` otherwise.
    ///
    func isPinUnlockAvailable() async throws -> Bool {
        try await isPinUnlockAvailable(userId: nil)
    }

    /// Locks the user's vault and clears decrypted data from memory
    /// - Parameters:
    ///   - userId: The userId of the account to lock. Defaults to active account if nil
    func lockVault(userId: String?) async {
        await lockVault(userId: userId, isManuallyLocking: false)
    }

    /// Logs the user out of the active account.
    ///
    /// - Parameter userInitiated: Whether the logout was user initiated or a result of a logout
    ///     timeout action.
    ///
    func logout(userInitiated: Bool) async throws {
        try await logout(userId: nil, userInitiated: userInitiated)
    }

    /// Whether master password reprompt should be performed.
    ///
    /// - Parameter reprompt: Cipher reprompt type to check
    /// - Returns: `true` if master password reprompt should be performed, `false` otherwise.
    func shouldPerformMasterPasswordReprompt(reprompt: BitwardenSdk.CipherRepromptType) async throws -> Bool {
        guard reprompt == .password else {
            return false
        }

        return try await canVerifyMasterPassword()
    }

    /// Gets the `SessionTimeoutAction` for the active account.
    ///
    func sessionTimeoutAction() async throws -> SessionTimeoutAction {
        try await sessionTimeoutAction(userId: nil)
    }

    /// Gets the `SessionTimeoutValue` for the active user.
    ///
    /// - Returns: The session timeout value.
    ///
    func sessionTimeoutValue() async throws -> SessionTimeoutValue {
        try await sessionTimeoutValue(userId: nil)
    }

    /// Sets the SessionTimeoutValue upon the app being backgrounded.
    ///
    /// - Parameter newValue: The timeout value.
    ///
    func setVaultTimeout(value newValue: SessionTimeoutValue) async throws {
        try await setVaultTimeout(value: newValue, userId: nil)
    }
}

// MARK: - DefaultAuthRepository

/// A default implementation of an `AuthRepository`.
///
class DefaultAuthRepository {
    // MARK: Properties

    /// The services used by the application to make account related API requests.
    private let accountAPIService: AccountAPIService

    /// Helper to know about the app context.
    private let appContextHelper: AppContextHelper

    /// The service used that handles some of the auth logic.
    private let authService: AuthService

    /// The service to use system Biometrics for vault unlock.
    let biometricsRepository: BiometricsRepository

    /// The service used to change the user's KDF settings.
    private let changeKdfService: ChangeKdfService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used by the application for recording temporary debug logs.
    private let flightRecorder: FlightRecorder

    /// The keychain service used by this repository.
    private let keychainService: KeychainRepository

    /// The service used by the application to manage Key Connector.
    private let keyConnectorService: KeyConnectorService

    /// The service used by the application to make organization-related API requests.
    private let organizationAPIService: OrganizationAPIService

    /// The service used to manage syncing and updates to the user's organizations.
    private let organizationService: OrganizationService

    /// The service used by the application to make organization user-related API requests.
    private let organizationUserAPIService: OrganizationUserAPIService

    /// The service used by the application to manage the policy.
    private var policyService: PolicyService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used by the application to manage trust device information.
    private let trustDeviceService: TrustDeviceService

    /// The service used by the application to manage user session state.
    private let userSessionStateService: UserSessionStateService

    /// The service used by the application to manage vault access.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultAuthRepository`.
    ///
    /// - Parameters:
    ///   - accountAPIService: The services used by the application to make account related API requests.
    ///   - appContextHelper: The helper to know about the app context.
    ///   - authService: The service used that handles some of the auth logic.
    ///   - biometricsRepository: The service to use system Biometrics for vault unlock.
    ///   - changeKdfService: The service used to change the user's KDF settings.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service to get server-specified configuration.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///   - keychainService: The keychain service used by the application.
    ///   - keyConnectorService: The service used by the application to manage Key Connector.
    ///   - organizationAPIService: The service used by the application to make organization-related API requests.
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - organizationUserAPIService: The service used by the application to make organization
    ///     user-related API requests.
    ///   - policyService: The service used by the application to manage the policy.
    ///   - stateService: The service used by the application to manage account state.
    ///   - trustDeviceService: The service used by the application to manage trust device information.
    ///   - userSessionStateService: The service used by the application to manage user session state.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        accountAPIService: AccountAPIService,
        appContextHelper: AppContextHelper,
        authService: AuthService,
        biometricsRepository: BiometricsRepository,
        changeKdfService: ChangeKdfService,
        clientService: ClientService,
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        flightRecorder: FlightRecorder,
        keychainService: KeychainRepository,
        keyConnectorService: KeyConnectorService,
        organizationAPIService: OrganizationAPIService,
        organizationService: OrganizationService,
        organizationUserAPIService: OrganizationUserAPIService,
        policyService: PolicyService,
        stateService: StateService,
        trustDeviceService: TrustDeviceService,
        userSessionStateService: UserSessionStateService,
        vaultTimeoutService: VaultTimeoutService,
    ) {
        self.accountAPIService = accountAPIService
        self.appContextHelper = appContextHelper
        self.authService = authService
        self.biometricsRepository = biometricsRepository
        self.changeKdfService = changeKdfService
        self.clientService = clientService
        self.configService = configService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.flightRecorder = flightRecorder
        self.keychainService = keychainService
        self.keyConnectorService = keyConnectorService
        self.organizationAPIService = organizationAPIService
        self.organizationService = organizationService
        self.organizationUserAPIService = organizationUserAPIService
        self.policyService = policyService
        self.stateService = stateService
        self.trustDeviceService = trustDeviceService
        self.userSessionStateService = userSessionStateService
        self.vaultTimeoutService = vaultTimeoutService
    }
}

// MARK: - AuthRepository

extension DefaultAuthRepository: AuthRepository {
    func allowBioMetricUnlock(_ enabled: Bool) async throws {
        try await biometricsRepository.setBiometricUnlockKey(
            authKey: enabled ? clientService.crypto().getUserEncryptionKey() : nil,
        )
    }

    func canBeLocked(userId: String?) async -> Bool {
        let hasMasterPassword: Bool = await (
            try? canVerifyMasterPassword(userId: userId)
        ) ?? false
        let isUnlockWithPinOn: Bool = await (
            try? isPinUnlockAvailable(userId: userId)
        ) ?? false
        let isUnlockWithBiometricOn: Bool = await (
            try? biometricsRepository.getBiometricUnlockStatus(userId: userId).isEnabled
        ) ?? false
        return hasMasterPassword || isUnlockWithPinOn || isUnlockWithBiometricOn
    }

    func canVerifyMasterPassword(userId: String? = nil) async throws -> Bool {
        try await stateService.getUserHasMasterPassword(userId: userId)
    }

    func checkSessionTimeouts(isAppRestart: Bool = false, handleActiveUser: ((String) async -> Void)? = nil) async {
        do {
            let accounts = try await getAccounts()
            guard !accounts.isEmpty else { return }
            let activeAccount = try await getActiveAccount()
            let activeUserId = activeAccount.userId

            for account in accounts {
                let userId = account.userId

                // Check time-based timeout
                let shouldTimeout = try await vaultTimeoutService.hasPassedSessionTimeout(
                    userId: userId,
                    isAppRestart: isAppRestart,
                )
                // Check if account can't be unlocked after restart (no master password, PIN, or biometrics)
                let shouldLogoutDueToNoUnlockMethod = !account.isUnlocked // Account locked
                    && !account.canBeLocked // Doesn't have an unlock method
                    && !account.isLoggedOut // Isn't already logged out (soft-logout)

                if shouldTimeout || shouldLogoutDueToNoUnlockMethod {
                    if userId == activeUserId {
                        await handleActiveUser?(activeUserId)
                    } else {
                        let timeoutAction = try await sessionTimeoutAction(userId: userId)
                        switch timeoutAction {
                        case .lock:
                            await vaultTimeoutService.lockVault(userId: userId)
                        case .logout:
                            try await logout(userId: userId, userInitiated: false)
                        }
                    }
                }
            }
        } catch StateServiceError.noAccounts, StateServiceError.noActiveAccount {
            // No-op: nothing to do if there's no accounts or an active account.
        } catch {
            errorReporter.log(error: error)
        }
    }

    func convertNewUserToKeyConnector(keyConnectorURL: URL, orgIdentifier: String) async throws {
        try await keyConnectorService.convertNewUserToKeyConnector(
            keyConnectorUrl: keyConnectorURL,
            orgIdentifier: orgIdentifier,
        )
    }

    func createNewSsoUser(orgIdentifier: String, rememberDevice: Bool) async throws {
        let account = try await stateService.getActiveAccount()
        let enrollStatus = try await organizationAPIService.getOrganizationAutoEnrollStatus(identifier: orgIdentifier)
        let organizationKeys = try await organizationAPIService.getOrganizationKeys(organizationId: enrollStatus.id)

        let registrationKeys = try await clientService.auth().makeRegisterTdeKeys(
            email: account.profile.email,
            orgPublicKey: organizationKeys.publicKey,
            rememberDevice: rememberDevice,
        )

        try await accountAPIService.setAccountKeys(requestModel: KeysRequestModel(
            encryptedPrivateKey: registrationKeys.privateKey,
            publicKey: registrationKeys.publicKey,
        ))

        try await stateService.setAccountEncryptionKeys(
            AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: registrationKeys.privateKey,
                encryptedUserKey: nil,
            ),
        )

        try await organizationUserAPIService.organizationUserResetPasswordEnrollment(
            organizationId: enrollStatus.id,
            requestModel: OrganizationUserResetPasswordEnrollmentRequestModel(
                masterPasswordHash: nil, resetPasswordKey: registrationKeys.adminReset,
            ),
            userId: account.profile.userId,
        )

        if rememberDevice,
           let trustDeviceResponse = registrationKeys.deviceKey {
            try await trustDeviceService.trustDeviceWithExistingKeys(keys: trustDeviceResponse)
        }
    }

    func clearPins() async throws {
        try await stateService.clearPins()
    }

    func deleteAccount(otp: String?, passwordText: String?) async throws {
        let hashedPassword: String? = if let passwordText {
            try await authService.hashPassword(password: passwordText, purpose: .serverAuthorization)
        } else {
            nil
        }

        _ = try await accountAPIService.deleteAccount(
            body: DeleteAccountRequestModel(
                masterPasswordHash: hashedPassword,
                otp: otp,
            ),
        )

        let userId = try await stateService.getActiveAccountId()
        await vaultTimeoutService.remove(userId: userId)

        // Delete the account last.
        try await stateService.deleteAccount()
    }

    func existingAccountUserId(email: String) async -> String? {
        let matchingUserIds = await stateService.getUserIds(email: email)
        for userId in matchingUserIds {
            // Skip unauthenticated user accounts, since the user may be trying to log back into an
            // account that was soft logged out.
            do {
                guard try await stateService.isAuthenticated(userId: userId) else { continue }
            } catch {
                errorReporter.log(error: error)
            }

            if let baseURL = try? await stateService.getEnvironmentURLs(userId: userId)?.base,
               baseURL == environmentService.baseURL {
                return userId
            }
        }
        return nil
    }

    func getAccount(for userId: String?) async throws -> Account {
        try await stateService.getAccount(userId: userId)
    }

    func getFingerprintPhrase() async throws -> String {
        let userId = try await stateService.getActiveAccountId()
        return try await clientService.platform().userFingerprint(material: userId)
    }

    func getProfilesState(
        allowLockAndLogout: Bool,
        isVisible: Bool,
        shouldAlwaysHideAddAccount: Bool,
        showPlaceholderToolbarIcon: Bool,
    ) async -> ProfileSwitcherState {
        let accounts = await (try? getAccounts()) ?? []
        guard !accounts.isEmpty else { return .empty() }
        let activeAccount = try? await getActiveAccount()
        return ProfileSwitcherState(
            accounts: accounts,
            activeAccountId: activeAccount?.userId,
            allowLockAndLogout: allowLockAndLogout,
            isVisible: isVisible,
            shouldAlwaysHideAddAccount: shouldAlwaysHideAddAccount,
            showPlaceholderToolbarIcon: showPlaceholderToolbarIcon,
        )
    }

    func getSingleSignOnOrganizationIdentifier(email: String) async throws -> String? {
        guard !email.isEmpty else {
            return nil
        }

        let verifiedDomainsResponse = try await organizationAPIService.getSingleSignOnVerifiedDomains(email: email)
        return verifiedDomainsResponse.verifiedDomains?.first?.organizationIdentifier?.nilIfEmpty
    }

    func hasMasterPassword() async throws -> Bool {
        let account = try await getAccount()
        guard let decryptionOptions = account.profile.userDecryptionOptions else { return true }
        return decryptionOptions.hasMasterPassword
    }

    func isLocked(userId: String?) async throws -> Bool {
        try await vaultTimeoutService.isLocked(userId: userIdOrActive(userId))
    }

    func isPinUnlockAvailable(userId: String?) async throws -> Bool {
        try await vaultTimeoutService.isPinUnlockAvailable(userId: userId)
    }

    func isUserManagedByOrganization() async throws -> Bool {
        let orgs = try await organizationService.fetchAllOrganizations()
        return orgs.contains { $0.userIsManagedByOrganization }
    }

    func lockAllVaults(isManuallyLocking: Bool) async throws {
        let accounts = try await stateService.getAccounts()
        guard !accounts.isEmpty else {
            return
        }

        for account in accounts {
            await lockVault(userId: account.profile.userId, isManuallyLocking: isManuallyLocking)
        }
    }

    func lockVault(userId: String?, isManuallyLocking: Bool) async {
        await vaultTimeoutService.lockVault(userId: userId)
        if isManuallyLocking {
            do {
                try await stateService.setManuallyLockedAccount(true, userId: userId)
            } catch {
                errorReporter.log(error: error)
            }
        }
    }

    func migrateUserToKeyConnector(password: String) async throws {
        try await keyConnectorService.migrateUser(password: password)
    }

    func leaveOrganization(organizationId: String) async throws {
        try await organizationAPIService.leaveOrganization(organizationId: organizationId)
    }

    func logout(userId: String?, userInitiated: Bool) async throws {
        let userId = try await stateService.getAccountIdOrActiveId(userId: userId)

        // Clear all user data.
        try await stateService.setSyncToAuthenticator(false, userId: userId)
        try await biometricsRepository.setBiometricUnlockKey(authKey: nil, userId: userId)
        try await keychainService.deleteItems(for: userId)
        await vaultTimeoutService.remove(userId: userId)

        if await policyService.policyAppliesToUser(.removeUnlockWithPin) {
            try await clearPins()
        }

        // Log the account out last.
        try await stateService.logoutAccount(userId: userId, userInitiated: userInitiated)
    }

    func passwordStrength(email: String, password: String, isPreAuth: Bool) async throws -> UInt8 {
        try await clientService.auth(isPreAuth: isPreAuth)
            .passwordStrength(password: password, email: email, additionalInputs: [])
    }

    func sessionTimeoutAction(userId: String?) async throws -> SessionTimeoutAction {
        try await vaultTimeoutService.sessionTimeoutAction(userId: userId)
    }

    func requestOtp() async throws {
        try await accountAPIService.requestOtp()
    }

    func revokeSelfFromOrganization(organizationId: String) async throws {
        try await organizationAPIService.revokeSelfFromOrganization(organizationId: organizationId)
    }

    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue {
        try await vaultTimeoutService.sessionTimeoutValue(userId: userId)
    }

    func setActiveAccount(userId: String) async throws -> Account {
        try await stateService.setActiveAccount(userId: userId)
        await environmentService.loadURLsForActiveAccount()
        _ = await configService.getConfig()
        return try await stateService.getActiveAccount()
    }

    func setMasterPassword( // swiftlint:disable:this function_body_length
        _ password: String,
        masterPasswordHint: String,
        organizationId: String,
        organizationIdentifier: String,
        resetPasswordAutoEnroll: Bool,
    ) async throws {
        let account = try await stateService.getActiveAccount()
        let email = account.profile.email
        let kdf = account.kdf
        let requestUserKey: String
        let requestKeys: KeysRequestModel?
        let requestPasswordHash: String
        let accountPrivateKeys: PrivateKeysResponseModel?
        let encryptedPrivateKey: String

        // TDE user
        if account.profile.userDecryptionOptions?.trustedDeviceOption != nil {
            let passwordResult = try await clientService.crypto().makeUpdatePassword(newPassword: password)
            let accountKeys = try await stateService.getAccountEncryptionKeys()
            requestPasswordHash = passwordResult.passwordHash
            requestUserKey = passwordResult.newKey
            requestKeys = nil
            accountPrivateKeys = accountKeys.accountKeys
            encryptedPrivateKey = accountKeys.encryptedPrivateKey
        } else {
            let keys = try await clientService.auth().makeRegisterKeys(
                email: email,
                password: password,
                kdf: kdf.sdkKdf,
            )
            requestPasswordHash = try await clientService.auth().hashPassword(
                email: email,
                password: password,
                kdfParams: kdf.sdkKdf,
                purpose: .serverAuthorization,
            )
            requestUserKey = keys.encryptedUserKey
            requestKeys = KeysRequestModel(
                encryptedPrivateKey: keys.keys.private,
                publicKey: keys.keys.public,
            )
            accountPrivateKeys = nil
            encryptedPrivateKey = keys.keys.private
        }

        let requestModel = SetPasswordRequestModel(
            kdfConfig: kdf,
            key: requestUserKey,
            keys: requestKeys,
            masterPasswordHash: requestPasswordHash,
            masterPasswordHint: masterPasswordHint,
            orgIdentifier: organizationIdentifier,
        )

        try await accountAPIService.setPassword(requestModel)
        try await stateService.setAccountEncryptionKeys(AccountEncryptionKeys(
            accountKeys: accountPrivateKeys,
            encryptedPrivateKey: encryptedPrivateKey,
            encryptedUserKey: requestUserKey,
        ))
        try await stateService.setUserHasMasterPassword(true)

        // The vault needs to be unlocked before attempting to enroll the user in admin password reset.
        try await unlockVaultWithPassword(password: password)

        if resetPasswordAutoEnroll {
            let organizationKeys = try await organizationAPIService.getOrganizationKeys(
                organizationId: organizationId,
            )

            let resetPasswordKey = try await clientService.crypto().enrollAdminPasswordReset(
                publicKey: organizationKeys.publicKey,
            )

            try await organizationUserAPIService.organizationUserResetPasswordEnrollment(
                organizationId: organizationId,
                requestModel: OrganizationUserResetPasswordEnrollmentRequestModel(
                    masterPasswordHash: requestPasswordHash,
                    resetPasswordKey: resetPasswordKey,
                ),
                userId: account.profile.userId,
            )
        }
    }

    func setPins(_ pin: String, requirePasswordAfterRestart: Bool) async throws {
        let enrollPinResponse = try await clientService.crypto().enrollPin(pin: pin)
        try await stateService.setPinKeys(
            enrollPinResponse: enrollPinResponse,
            requirePasswordAfterRestart: requirePasswordAfterRestart,
        )
    }

    func setVaultTimeout(value newValue: SessionTimeoutValue, userId: String?) async throws {
        // Ensure we have a user id.
        let id = try await userIdOrActive(userId)
        let currentValue = try? await vaultTimeoutService.sessionTimeoutValue(userId: id)
        // Set or delete the never lock key according to the current and new values.
        if case .never = newValue {
            try await keychainService.setUserAuthKey(
                for: .neverLock(userId: id),
                value: clientService.crypto().getUserEncryptionKey(),
            )
        } else if currentValue == .never {
            // If there is a key, delete. If not, no worries.
            try? await keychainService.deleteUserAuthKey(
                for: .neverLock(userId: id),
            )
        }

        // Then configure the vault timeout service with the correct value.
        try await vaultTimeoutService.setVaultTimeout(
            value: newValue,
            userId: id,
        )
    }

    func unlockVaultFromLoginWithDevice(privateKey: String, key: String, masterPasswordHash: String?) async throws {
        let method =
            if masterPasswordHash != nil,
            let encUserKey = try await stateService.getAccountEncryptionKeys().encryptedUserKey {
                AuthRequestMethod.masterKey(protectedMasterKey: key, authRequestKey: encUserKey)
            } else {
                AuthRequestMethod.userKey(protectedUserKey: key)
            }

        try await unlockVault(
            method: .authRequest(
                requestPrivateKey: privateKey,
                method: method,
            ),
        )

        // Remove admin pending login request if exists
        try await authService.setPendingAdminLoginRequest(nil, userId: nil)
    }

    func unlockVaultWithBiometrics() async throws {
        let decryptedUserKey = try await biometricsRepository.getUserAuthKey()
        try await unlockVault(method: .decryptedKey(decryptedUserKey: decryptedUserKey))
    }

    func unlockVaultWithDeviceKey() async throws {
        let id = try await stateService.getActiveAccountId()
        let decryptionOption = try await stateService.getActiveAccount().profile.userDecryptionOptions

        guard let deviceKey = try await keychainService.getDeviceKey(userId: id) else {
            throw AuthError.missingDeviceKey
        }

        guard let protectedDevicePrivateKey = decryptionOption?.trustedDeviceOption?.encryptedPrivateKey,
              let deviceProtectedUserKey = decryptionOption?.trustedDeviceOption?.encryptedUserKey else {
            throw AuthError.missingUserDecryptionOptions
        }

        try await unlockVault(method: .deviceKey(
            deviceKey: deviceKey,
            protectedDevicePrivateKey: protectedDevicePrivateKey,
            deviceProtectedUserKey: deviceProtectedUserKey,
        ))
    }

    func unlockVaultWithKeyConnectorKey(keyConnectorURL: URL, orgIdentifier: String) async throws {
        let account = try await stateService.getActiveAccount()

        let encryptionKeys = try await stateService.getAccountEncryptionKeys(userId: account.profile.userId)

        guard let encryptedUserKey = encryptionKeys.encryptedUserKey else { throw StateServiceError.noEncUserKey }

        let masterKey = try await keyConnectorService.getMasterKeyFromKeyConnector(
            keyConnectorUrl: keyConnectorURL,
        )
        try await unlockVault(method: .keyConnector(masterKey: masterKey, userKey: encryptedUserKey))
    }

    func unlockVaultWithNeverlockKey() async throws {
        let id = try await stateService.getActiveAccountId()
        let key = KeychainItem.neverLock(userId: id)
        let neverlockKey = try await keychainService.getUserAuthKeyValue(for: key)
        try await unlockVault(method: .decryptedKey(decryptedUserKey: neverlockKey), hadUserInteraction: false)
    }

    func unlockVaultWithPassword(password: String) async throws {
        let account = try await stateService.getActiveAccount()

        guard let masterPasswordUnlock = account.profile.userDecryptionOptions?.masterPasswordUnlock else {
            throw AuthError.missingMasterPasswordUnlockData
        }

        let unlockMethod: InitUserCryptoMethod = .masterPasswordUnlock(
            password: password,
            masterPasswordUnlock: MasterPasswordUnlockData(responseModel: masterPasswordUnlock),
        )
        try await unlockVault(method: unlockMethod)

        let hashedPassword = try await authService.hashPassword(
            password: password,
            purpose: .localAuthorization,
        )
        try await stateService.setMasterPasswordHash(hashedPassword)
        await updateKdfToMinimumsIfNeeded(password: password)
    }

    func unlockVaultWithPIN(pin: String) async throws {
        if let pinProtectedUserKeyEnvelope = try await stateService.pinProtectedUserKeyEnvelope() {
            try await unlockVault(
                method: .pinEnvelope(
                    pin: pin,
                    pinProtectedUserKeyEnvelope: pinProtectedUserKeyEnvelope,
                ),
            )
        } else {
            // This is needed to support unlocking with a legacy pin protected user key. Once the
            // vault is unlocked, the user's pin protected user key is migrated to a pin protected
            // user key envelope.
            guard let pinProtectedUserKey = try await stateService.pinProtectedUserKey() else {
                throw StateServiceError.noPinProtectedUserKey
            }
            try await unlockVault(method: .pin(pin: pin, pinProtectedUserKey: pinProtectedUserKey))
        }
    }

    func validatePassword(_ password: String) async throws -> Bool {
        if let passwordHash = try await stateService.getMasterPasswordHash() {
            return try await clientService.auth().validatePassword(password: password, passwordHash: passwordHash)
        } else {
            let encryptionKeys = try await stateService.getAccountEncryptionKeys()
            guard let encUserKey = encryptionKeys.encryptedUserKey else { throw StateServiceError.noEncUserKey }
            do {
                let passwordHash = try await clientService.auth().validatePasswordUserKey(
                    password: password,
                    encryptedUserKey: encUserKey,
                )
                try await stateService.setMasterPasswordHash(passwordHash)
                return true
            } catch {
                Logger.application.log("Error validating password user key: \(error)")
                return false
            }
        }
    }

    func validatePin(pin: String) async throws -> Bool {
        guard let pinProtectedUserKey = try? await stateService.pinProtectedUserKey() else {
            return false
        }

        return try await clientService.auth().validatePin(pin: pin, pinProtectedUserKey: pinProtectedUserKey)
    }

    func verifyOtp(_ otp: String) async throws {
        try await accountAPIService.verifyOtp(otp)
    }

    // MARK: Private

    /// A helper function to convert state service `Account`s to `ProfileSwitcherItem`s.
    ///
    /// - Returns: A list of available accounts as `[ProfileSwitcherItem]`.
    ///
    private func getAccounts() async throws -> [ProfileSwitcherItem] {
        let accounts = try await stateService.getAccounts()
        return await accounts.asyncMap { account in
            await profileItem(from: account)
        }
    }

    /// A helper function to convert the state service active `Account` to a `ProfileSwitcherItem`.
    ///
    /// - Returns: The active account as a `ProfileSwitcherItem`.
    ///
    private func getActiveAccount() async throws -> ProfileSwitcherItem {
        let active = try await stateService.getActiveAccount()
        return await profileItem(from: active)
    }

    /// A function to convert an `Account` to a `ProfileSwitcherItem`
    ///
    ///   - Parameter account: The account to convert.
    ///   - Returns: The `ProfileSwitcherItem` representing the account.
    ///
    private func profileItem(from account: Account) async -> ProfileSwitcherItem {
        let isLocked = await (try? isLocked(userId: account.profile.userId)) ?? true
        let isAuthenticated = await (try? stateService.isAuthenticated(userId: account.profile.userId)) == true
        let hasNeverLock = await (try? userSessionStateService.getVaultTimeout(userId: account.profile.userId)) == .never
        let isManuallyLocked = await (try? stateService.getManuallyLockedAccount(
            userId: account.profile.userId,
        )) == true
        let unlockedOnNeverLock = hasNeverLock && !isManuallyLocked
        let displayAsUnlocked = !isLocked || unlockedOnNeverLock

        let color = if let avatarColor = account.profile.avatarColor {
            Color(hex: avatarColor)
        } else {
            account.profile.userId.hashColor
        }

        let canBeLocked = await canBeLocked(userId: account.profile.userId)

        return ProfileSwitcherItem(
            canBeLocked: canBeLocked,
            color: color,
            email: account.profile.email,
            isLoggedOut: !isAuthenticated,
            isUnlocked: displayAsUnlocked,
            userId: account.profile.userId,
            userInitials: account.initials(),
            webVault: account.settings.environmentUrls?.webVaultHost ?? "",
        )
    }

    /// Attempts to unlock the vault with a given method.
    ///
    /// - Parameters:
    ///   - method: The unlocking `InitUserCryptoMethod` method
    ///   - hadUserInteraction: If the user interacted with the app to unlock the vault
    ///   or was unlocked using the never lock key.
    private func unlockVault(method: InitUserCryptoMethod, hadUserInteraction: Bool = true) async throws {
        let account = try await stateService.getActiveAccount()
        let encryptionKeys = try await stateService.getAccountEncryptionKeys()

        try await clientService.crypto().initializeUserCrypto(
            account: account,
            encryptionKeys: encryptionKeys,
            method: method,
        )

        await flightRecorder.log("[Auth] Vault unlocked, method: \(method.methodType)")

        try await configurePinUnlockIfNeeded(method: method)

        _ = try await trustDeviceService.trustDeviceIfNeeded()
        try await vaultTimeoutService.unlockVault(
            userId: account.profile.userId,
            hadUserInteraction: hadUserInteraction,
        )
        try await organizationService.initializeOrganizationCrypto()
        do {
            try await stateService.setManuallyLockedAccount(false, userId: account.profile.userId)
        } catch {
            errorReporter.log(error: error)
        }
    }

    /// Updates the user's KDF settings to the minimums.
    ///
    /// - Parameter password: The user's master password.
    ///
    private func updateKdfToMinimumsIfNeeded(password: String) async {
        do {
            try await changeKdfService.updateKdfToMinimumsIfNeeded(password: password)
        } catch {
            // If an error occurs, log the error. Don't throw since that would block the vault from
            // unlocking.
            errorReporter.log(error: error)
        }
    }

    func updateMasterPassword(
        currentPassword: String,
        newPassword: String,
        passwordHint: String,
        reason: ForcePasswordResetReason,
    ) async throws {
        let account = try await stateService.getActiveAccount()
        let updatePasswordResponse = try await clientService.crypto().makeUpdatePassword(newPassword: newPassword)

        let masterPasswordHash = try await clientService.auth().hashPassword(
            email: account.profile.email,
            password: currentPassword,
            kdfParams: account.kdf.sdkKdf,
            purpose: .serverAuthorization,
        )

        let encryptionKeys = try await stateService.getAccountEncryptionKeys()
        let newEncryptionKeys = AccountEncryptionKeys(
            accountKeys: encryptionKeys.accountKeys,
            encryptedPrivateKey: encryptionKeys.encryptedPrivateKey,
            encryptedUserKey: updatePasswordResponse.newKey,
        )

        switch reason {
        case .adminForcePasswordReset:
            try await accountAPIService.updateTempPassword(
                UpdateTempPasswordRequestModel(
                    key: updatePasswordResponse.newKey,
                    masterPasswordHint: passwordHint,
                    newMasterPasswordHash: updatePasswordResponse.passwordHash,
                ),
            )
        case .weakMasterPasswordOnLogin:
            try await accountAPIService.updatePassword(
                UpdatePasswordRequestModel(
                    key: updatePasswordResponse.newKey,
                    masterPasswordHash: masterPasswordHash,
                    masterPasswordHint: passwordHint,
                    newMasterPasswordHash: updatePasswordResponse.passwordHash,
                ),
            )
        }

        try await stateService.setAccountEncryptionKeys(newEncryptionKeys)
        try await stateService.setMasterPasswordHash(updatePasswordResponse.passwordHash)
        try await stateService.setForcePasswordResetReason(nil)
    }

    /// Returns the provided user ID if it exists, otherwise fetches the active account's ID.
    ///
    /// - Parameter maybeId: The optional user ID to check.
    /// - Returns: The user ID if provided, otherwise the active account's ID.
    /// - Throws: An error if fetching the active account ID fails.
    ///
    private func userIdOrActive(_ maybeId: String?) async throws -> String {
        if let maybeId { return maybeId }
        return try await stateService.getActiveAccountId()
    }

    /// Configures PIN unlock if the user requires master password or biometrics after an app restart.
    ///
    /// - Parameter method: The unlocking `InitUserCryptoMethod` method.
    ///
    private func configurePinUnlockIfNeeded(method: InitUserCryptoMethod) async throws {
        guard let encryptedPin = try await stateService.getEncryptedPin(),
              let enrollPinResponse = try await enrollPinWithErrorHandling(encryptedPin: encryptedPin)
        else {
            return
        }

        // `pinProtectedUserKey` is a legacy PIN-protected user key or
        // in-memory PIN-protected user key envelope (MP required after restart).
        let pinProtectedUserKey = try await stateService.pinProtectedUserKey()
        // Master password is required after restart if there's no stored PIN-protected user key
        // envelope or legacy PIN-protected user key.
        let pinUnlockRequiresPasswordAfterRestart = try await stateService.pinUnlockRequiresPasswordAfterRestart()

        if pinProtectedUserKey != nil, !pinUnlockRequiresPasswordAfterRestart {
            // The stored PIN-protected user key needs to be migrated to a PIN-protected user key envelope.
            try await stateService.setPinKeys(
                enrollPinResponse: enrollPinResponse,
                requirePasswordAfterRestart: pinUnlockRequiresPasswordAfterRestart,
            )
            await flightRecorder.log("[Auth] Migrated from legacy PIN to PIN-protected user key envelope")
        } else if pinProtectedUserKey == nil, pinUnlockRequiresPasswordAfterRestart {
            // If the user has a PIN (encryptedPin), but requires master password after restart, set
            // the PIN-protected user key in memory for future unlocks prior to app restart.
            try await stateService.setPinProtectedUserKeyToMemory(enrollPinResponse.pinProtectedUserKeyEnvelope)
            await flightRecorder.log("[Auth] Set PIN-protected user key in memory")
        }
    }

    /// Attempts to enroll a PIN with error handling for key rotation scenarios.
    ///
    /// This method wraps the SDK's `enrollPinWithEncryptedPin` call and handles errors that occur when
    /// the user's encryption key has been rotated, making the existing PIN keys invalid. If enrollment
    /// fails, the PIN keys are cleared to maintain a consistent state.
    ///
    /// - Parameter encryptedPin: The encrypted PIN to enroll.
    /// - Returns: The `EnrollPinResponse` if enrollment succeeds, or `nil` if it fails (allowing the
    ///   unlock process to continue without erroring).
    /// - Throws: An error if clearing the PIN keys fails.
    ///
    private func enrollPinWithErrorHandling(encryptedPin: String) async throws -> EnrollPinResponse? {
        do {
            return try await clientService.crypto().enrollPinWithEncryptedPin(encryptedPin: encryptedPin)
        } catch {
            await flightRecorder.log("[Auth] enrollPinWithEncryptedPin failed: \(error), clearing existing PIN keys")
            // If `enrollPinWithEncryptedPin` fails, the user's key was likely rotated and the
            // existing PIN keys need to be removed since they are no longer valid.
            // Note: We handle all errors broadly here because the SDK doesn't provide specific
            // error types to distinguish key rotation failures from other errors. Clearing the
            // PIN keys on any error is the safest approach to maintain data consistency.
            try await stateService.clearPins()
            // Return `nil` instead of throwing to avoid erroring out of the unlock process.
            return nil
        }
    }
}
