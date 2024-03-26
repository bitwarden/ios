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

    /// Clears the pins stored on device and in memory.
    ///
    func clearPins() async throws

    /// Deletes the user's account.
    ///
    /// - Parameter passwordText: The password entered by the user, which is used to verify
    /// their identify before deleting the account.
    ///
    func deleteAccount(passwordText: String) async throws

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

    /// Whether pin unlock is available.
    ///
    /// - Returns: Whether pin unlock is available.
    ///
    func isPinUnlockAvailable() async throws -> Bool

    /// Checks the locked status of a user vault by user id
    ///  - Parameter userId: The userId of the account
    ///  - Returns: A bool, true if locked, false if unlocked.
    ///
    func isLocked(userId: String?) async throws -> Bool

    /// Locks the user's vault and clears decrypted data from memory.
    ///
    ///  - Parameter userId: The userId of the account to lock.
    ///     Defaults to active account if nil.
    ///
    func lockVault(userId: String?) async

    /// Logs the user out of the specified account.
    ///
    /// - Parameter userId: The user ID of the account to log out of.
    ///
    func logout(userId: String?) async throws

    /// Calculates the password strength of a password.
    ///
    /// - Parameters:
    ///   - email: The user's email.
    ///   - password: The user's password.
    /// - Returns: The password strength of the password.
    ///
    func passwordStrength(email: String, password: String) async -> UInt8

    /// Gets the profiles state for a user.
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
        showPlaceholderToolbarIcon: Bool
    ) async -> ProfileSwitcherState

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
        resetPasswordAutoEnroll: Bool
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
        reason: ForcePasswordResetReason
    ) async throws

    /// Validates the user's entered master password to determine if it matches the stored hash.
    ///
    /// - Parameter password: The user's master password.
    /// - Returns: Whether the hash of the password matches the stored hash.
    ///
    func validatePassword(_ password: String) async throws -> Bool
}

extension AuthRepository {
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

    /// Logs the user out of the active account.
    ///
    func logout() async throws {
        try await logout(userId: nil)
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

    /// The service used that handles some of the auth logic.
    private let authService: AuthService

    /// The service to use system Biometrics for vault unlock.
    let biometricsRepository: BiometricsRepository

    /// The client used by the application to handle auth related encryption and decryption tasks.
    private let clientAuth: ClientAuthProtocol

    /// The client used by the application to handle encryption and decryption setup tasks.
    private let clientCrypto: ClientCryptoProtocol

    /// The client used by the application to handle account fingerprint phrase generation.
    private let clientPlatform: ClientPlatformProtocol

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The keychain service used by this repository.
    private let keychainService: KeychainRepository

    /// The service used by the application to make organization-related API requests.
    private let organizationAPIService: OrganizationAPIService

    /// The service used to manage syncing and updates to the user's organizations.
    private let organizationService: OrganizationService

    /// The service used by the application to make organization user-related API requests.
    private let organizationUserAPIService: OrganizationUserAPIService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used by the application to manage trust device information.
    private let trustDeviceService: TrustDeviceService

    /// The service used by the application to manage vault access.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultAuthRepository`.
    ///
    /// - Parameters:
    ///   - accountAPIService: The services used by the application to make account related API requests.
    ///   - authService: The service used that handles some of the auth logic.
    ///   - biometricsRepository: The service to use system Biometrics for vault unlock.
    ///   - clientAuth: The client used by the application to handle auth related encryption and decryption tasks.
    ///   - clientCrypto: The client used by the application to handle encryption and decryption setup tasks.
    ///   - clientPlatform: The client used by the application to handle generating account fingerprints.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - keychainService: The keychain service used by the application.
    ///   - organizationAPIService: The service used by the application to make organization-related API requests.
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - organizationUserAPIService: The service used by the application to make organization
    ///     user-related API requests.
    ///   - stateService: The service used by the application to manage account state.
    ///   - trustDeviceService: The service used by the application to manage trust device information.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        accountAPIService: AccountAPIService,
        authService: AuthService,
        biometricsRepository: BiometricsRepository,
        clientAuth: ClientAuthProtocol,
        clientCrypto: ClientCryptoProtocol,
        clientPlatform: ClientPlatformProtocol,
        environmentService: EnvironmentService,
        keychainService: KeychainRepository,
        organizationAPIService: OrganizationAPIService,
        organizationService: OrganizationService,
        organizationUserAPIService: OrganizationUserAPIService,
        stateService: StateService,
        trustDeviceService: TrustDeviceService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.accountAPIService = accountAPIService
        self.authService = authService
        self.biometricsRepository = biometricsRepository
        self.clientAuth = clientAuth
        self.clientCrypto = clientCrypto
        self.clientPlatform = clientPlatform
        self.environmentService = environmentService
        self.keychainService = keychainService
        self.organizationAPIService = organizationAPIService
        self.organizationService = organizationService
        self.organizationUserAPIService = organizationUserAPIService
        self.stateService = stateService
        self.trustDeviceService = trustDeviceService
        self.vaultTimeoutService = vaultTimeoutService
    }
}

// MARK: - AuthRepository

extension DefaultAuthRepository: AuthRepository {
    func allowBioMetricUnlock(_ enabled: Bool) async throws {
        try await biometricsRepository.setBiometricUnlockKey(
            authKey: enabled ? clientCrypto.getUserEncryptionKey() : nil
        )
    }

    func clearPins() async throws {
        try await stateService.clearPins()
    }

    func deleteAccount(passwordText: String) async throws {
        let hashedPassword = try await authService.hashPassword(password: passwordText, purpose: .serverAuthorization)

        _ = try await accountAPIService.deleteAccount(
            body: DeleteAccountRequestModel(masterPasswordHash: hashedPassword)
        )

        try await stateService.deleteAccount()
        await vaultTimeoutService.remove(userId: nil)
    }

    func getAccount(for userId: String?) async throws -> Account {
        try await stateService.getAccount(userId: userId)
    }

    func getFingerprintPhrase() async throws -> String {
        let userId = try await stateService.getActiveAccountId()
        return try await clientPlatform.userFingerprint(fingerprintMaterial: userId)
    }

    func getProfilesState(
        allowLockAndLogout: Bool,
        isVisible: Bool,
        shouldAlwaysHideAddAccount: Bool,
        showPlaceholderToolbarIcon: Bool
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
            showPlaceholderToolbarIcon: showPlaceholderToolbarIcon
        )
    }

    func isLocked(userId: String?) async throws -> Bool {
        try await vaultTimeoutService.isLocked(
            userId: userIdOrActive(userId)
        )
    }

    func isPinUnlockAvailable() async throws -> Bool {
        try await stateService.pinProtectedUserKey() != nil
    }

    func lockVault(userId: String?) async {
        await vaultTimeoutService.lockVault(userId: userId)
    }

    func logout(userId: String?) async throws {
        try? await biometricsRepository.setBiometricUnlockKey(authKey: nil)
        await vaultTimeoutService.remove(userId: userId)
        try await stateService.logoutAccount(userId: userId)
    }

    func passwordStrength(email: String, password: String) async -> UInt8 {
        await clientAuth.passwordStrength(password: password, email: email, additionalInputs: [])
    }

    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue {
        try await vaultTimeoutService.sessionTimeoutValue(userId: userId)
    }

    func setActiveAccount(userId: String) async throws -> Account {
        try await stateService.setActiveAccount(userId: userId)
        await environmentService.loadURLsForActiveAccount()
        return try await stateService.getActiveAccount()
    }

    func setMasterPassword(
        _ password: String,
        masterPasswordHint: String,
        organizationId: String,
        organizationIdentifier: String,
        resetPasswordAutoEnroll: Bool
    ) async throws {
        let account = try await stateService.getActiveAccount()
        let email = account.profile.email
        let kdf = account.kdf

        let keys = try await clientAuth.makeRegisterKeys(
            email: email,
            password: password,
            kdf: kdf.sdkKdf
        )

        let masterPasswordHash = try await clientAuth.hashPassword(
            email: email,
            password: password,
            kdfParams: kdf.sdkKdf,
            purpose: .serverAuthorization
        )

        let requestModel = SetPasswordRequestModel(
            kdfConfig: kdf,
            key: keys.encryptedUserKey,
            keys: KeysRequestModel(publicKey: keys.keys.public, encryptedPrivateKey: keys.keys.private),
            masterPasswordHash: masterPasswordHash,
            masterPasswordHint: masterPasswordHint,
            orgIdentifier: organizationIdentifier
        )
        try await accountAPIService.setPassword(requestModel)

        let accountEncryptionKeys = AccountEncryptionKeys(
            encryptedPrivateKey: keys.keys.private,
            encryptedUserKey: keys.encryptedUserKey
        )
        try await stateService.setAccountEncryptionKeys(accountEncryptionKeys)

        if resetPasswordAutoEnroll {
            let organizationKeys = try await organizationAPIService.getOrganizationKeys(
                organizationId: organizationId
            )

            let resetPasswordKey = try await clientCrypto.enrollAdminPasswordReset(
                publicKey: organizationKeys.publicKey
            )

            try await organizationUserAPIService.organizationUserResetPasswordEnrollment(
                organizationId: organizationId,
                requestModel: OrganizationUserResetPasswordEnrollmentRequestModel(
                    masterPasswordHash: masterPasswordHash,
                    resetPasswordKey: resetPasswordKey
                ),
                userId: account.profile.userId
            )
        }

        try await unlockVaultWithPassword(password: password)
    }

    func setPins(_ pin: String, requirePasswordAfterRestart: Bool) async throws {
        let pinKey = try await clientCrypto.derivePinKey(pin: pin)
        try await stateService.setPinKeys(
            pinKeyEncryptedUserKey: pinKey.encryptedPin,
            pinProtectedUserKey: pinKey.pinProtectedUserKey,
            requirePasswordAfterRestart: requirePasswordAfterRestart
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
                value: clientCrypto.getUserEncryptionKey()
            )
        } else if currentValue == .never {
            // If there is a key, delete. If not, no worries.
            try? await keychainService.deleteUserAuthKey(
                for: .neverLock(userId: id)
            )
        }

        // Then configure the vault timeout service with the correct value.
        try await vaultTimeoutService.setVaultTimeout(
            value: newValue,
            userId: id
        )
    }

    func unlockVaultFromLoginWithDevice(privateKey: String, key: String, masterPasswordHash: String?) async throws {
        let method: AuthRequestMethod =
            if masterPasswordHash != nil,
            let encUserKey = try await stateService.getAccountEncryptionKeys().encryptedUserKey {
                AuthRequestMethod.masterKey(protectedMasterKey: key, authRequestKey: encUserKey)
            } else {
                AuthRequestMethod.userKey(protectedUserKey: key)
            }

        try await unlockVault(
            method: .authRequest(
                requestPrivateKey: privateKey,
                method: method
            )
        )
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
            protectedDevicePrivateKey: protectedDevicePrivateKey as EncString,
            deviceProtectedUserKey: deviceProtectedUserKey as AsymmetricEncString
        ))
    }

    func unlockVaultWithNeverlockKey() async throws {
        let id = try await stateService.getActiveAccountId()
        let key = KeychainItem.neverLock(userId: id)
        let neverlockKey = try await keychainService.getUserAuthKeyValue(for: key)
        try await unlockVault(method: .decryptedKey(decryptedUserKey: neverlockKey))
    }

    func unlockVaultWithPassword(password: String) async throws {
        let account = try await stateService.getActiveAccount()
        let encryptionKeys = try await stateService.getAccountEncryptionKeys(userId: account.profile.userId)
        guard let encUserKey = encryptionKeys.encryptedUserKey else { throw StateServiceError.noEncUserKey }
        try await unlockVault(method: .password(password: password, userKey: encUserKey))
    }

    func unlockVaultWithPIN(pin: String) async throws {
        guard let pinProtectedUserKey = try await stateService.pinProtectedUserKey() else {
            throw StateServiceError.noPinProtectedUserKey
        }
        try await unlockVault(method: .pin(pin: pin, pinProtectedUserKey: pinProtectedUserKey))
    }

    func validatePassword(_ password: String) async throws -> Bool {
        if let passwordHash = try await stateService.getMasterPasswordHash() {
            return try await clientAuth.validatePassword(password: password, passwordHash: passwordHash)
        } else {
            let encryptionKeys = try await stateService.getAccountEncryptionKeys()
            guard let encUserKey = encryptionKeys.encryptedUserKey else { throw StateServiceError.noEncUserKey }
            do {
                let passwordHash = try await clientAuth.validatePasswordUserKey(
                    password: password,
                    encryptedUserKey: encUserKey
                )
                try await stateService.setMasterPasswordHash(passwordHash)
                return true
            } catch {
                Logger.application.log("Error validating password user key: \(error)")
                return false
            }
        }
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
        let hasNeverLock = await (try? stateService
            .getVaultTimeout(userId: account.profile.userId)) == .never
        let displayAsUnlocked = !isLocked || hasNeverLock

        let color = if let avatarColor = account.profile.avatarColor {
            Color(hex: avatarColor)
        } else {
            account.profile.userId.hashColor
        }

        return ProfileSwitcherItem(
            color: color,
            email: account.profile.email,
            isUnlocked: displayAsUnlocked,
            userId: account.profile.userId,
            userInitials: account.initials(),
            webVault: account.settings.environmentUrls?.webVaultHost ?? ""
        )
    }

    /// Attempts to unlock the vault with a given method.
    ///
    /// - Parameter method: The unlocking `InitUserCryptoMethod` method.
    ///
    private func unlockVault(method: InitUserCryptoMethod) async throws {
        let account = try await stateService.getActiveAccount()
        let encryptionKeys = try await stateService.getAccountEncryptionKeys()

        try await clientCrypto.initializeUserCrypto(
            req: InitUserCryptoRequest(
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                privateKey: encryptionKeys.encryptedPrivateKey,
                method: method
            )
        )

        switch method {
        case .authRequest:
            break
        case .decryptedKey:
            // No-op: nothing extra to do for decryptedKey.
            break
        case .deviceKey:
            // No-op: nothing extra (for now).
            break
        case let .password(password, _):
            let hashedPassword = try await authService.hashPassword(
                password: password,
                purpose: .localAuthorization
            )
            try await stateService.setMasterPasswordHash(hashedPassword)

            // If the user has a pin, but requires master password after restart, set the pin
            // protected user key in memory for future unlocks prior to app restart.
            if let pinKeyEncryptedUserKey = try await stateService.pinKeyEncryptedUserKey() {
                let pinProtectedUserKey = try await clientCrypto.derivePinUserKey(encryptedPin: pinKeyEncryptedUserKey)
                try await stateService.setPinProtectedUserKeyToMemory(pinProtectedUserKey)
            }

            // Re-enable biometrics, if required.
            let biometricUnlockStatus = try? await biometricsRepository.getBiometricUnlockStatus()
            switch biometricUnlockStatus {
            case .available(_, true, false):
                try await biometricsRepository.configureBiometricIntegrity()
                try await biometricsRepository.setBiometricUnlockKey(
                    authKey: clientCrypto.getUserEncryptionKey()
                )
            default:
                break
            }
        case .pin:
            // No-op: nothing extra to do for pin unlock.
            break
        }

        _ = try await trustDeviceService.trustDeviceIfNeeded()
        await vaultTimeoutService.unlockVault(userId: account.profile.userId)
        try await organizationService.initializeOrganizationCrypto()
    }

    func updateMasterPassword(
        currentPassword: String,
        newPassword: String,
        passwordHint: String,
        reason: ForcePasswordResetReason
    ) async throws {
        let account = try await stateService.getActiveAccount()
        let updatePasswordResponse = try await clientCrypto.updatePassword(newPassword: newPassword)

        let masterPasswordHash = try await clientAuth.hashPassword(
            email: account.profile.email,
            password: currentPassword,
            kdfParams: account.kdf.sdkKdf,
            purpose: .serverAuthorization
        )

        let encryptionKeys = try await stateService.getAccountEncryptionKeys()
        let newEncryptionKeys = AccountEncryptionKeys(
            encryptedPrivateKey: encryptionKeys.encryptedPrivateKey,
            encryptedUserKey: updatePasswordResponse.newKey
        )

        switch reason {
        case .adminForcePasswordReset:
            try await accountAPIService.updateTempPassword(
                UpdateTempPasswordRequestModel(
                    key: updatePasswordResponse.newKey,
                    masterPasswordHint: passwordHint,
                    newMasterPasswordHash: updatePasswordResponse.passwordHash
                )
            )
        case .weakMasterPasswordOnLogin:
            try await accountAPIService.updatePassword(
                UpdatePasswordRequestModel(
                    key: updatePasswordResponse.newKey,
                    masterPasswordHash: masterPasswordHash,
                    masterPasswordHint: passwordHint,
                    newMasterPasswordHash: updatePasswordResponse.passwordHash
                )
            )
        }

        try await stateService.setAccountEncryptionKeys(newEncryptionKeys)
        try await stateService.setMasterPasswordHash(updatePasswordResponse.passwordHash)
        try await stateService.setForcePasswordResetReason(nil)
    }

    private func userIdOrActive(_ maybeId: String?) async throws -> String {
        if let maybeId { return maybeId }
        return try await stateService.getActiveAccountId()
    }
}
