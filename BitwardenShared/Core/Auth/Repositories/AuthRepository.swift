import BitwardenSdk
import Foundation
import LocalAuthentication

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
    ///   - userId: The user Id to be configured.
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

    /// Gets all accounts.
    ///
    /// - Returns: The known user accounts as `[ProfileSwitcherItem]`.
    ///
    func getAccounts() async throws -> [ProfileSwitcherItem]

    /// Gets the active account.
    ///
    /// - Returns: The active user account as a `ProfileSwitcherItem`.
    ///
    func getActiveAccount() async throws -> ProfileSwitcherItem

    /// Gets the account for a `ProfileSwitcherItem`.
    ///
    /// - Parameter userId: The user Id to be mapped to an account.
    /// - Returns: The user account.
    ///
    func getAccount(for userId: String) async throws -> Account

    /// Gets the account's unique fingerprint phrase.
    ///
    /// - Parameter userId: The user Id used in generating a fingerprint phrase.
    /// - Returns: The account fingerprint phrase.
    ///
    func getFingerprintPhrase(userId _: String?) async throws -> String

    /// Initiates the login with device process.
    ///
    /// - Parameters:
    ///   - deviceId: The device ID.
    ///   - email: The user's email.
    ///
    /// - Returns: A fingerprint to use in the `PasswordlessLoginRequest`.
    ///
    func initiateLoginWithDevice(deviceId: String, email: String) async throws -> String

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

    /// Sets the SessionTimeoutValue.
    ///
    /// - Parameters:
    ///   - value: The timeout value.
    ///   - userId: The user's ID.
    ///
    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws

    /// Attempts to unlock the user's vault with biometrics.
    ///
    func unlockVaultWithBiometrics() async throws

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
}

extension AuthRepository {
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

    /// Sets the SessionTimeoutValue upon the app being backgrounded.
    ///
    /// - Parameter value: The timeout value.
    ///
    func setVaultTimeout(value: SessionTimeoutValue) async throws {
        try await setVaultTimeout(value: value, userId: nil)
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
    private let keychainService: KeychainService

    /// The service used to manage syncing and updates to the user's organizations.
    private let organizationService: OrganizationService

    /// The service used by the application to manage account state.
    private let stateService: StateService

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
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - stateService: The service used by the application to manage account state.
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
        keychainService: KeychainService,
        organizationService: OrganizationService,
        stateService: StateService,
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
        self.organizationService = organizationService
        self.stateService = stateService
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

    func getAccounts() async throws -> [ProfileSwitcherItem] {
        let accounts = try await stateService.getAccounts()
        return await accounts.asyncMap { account in
            await profileItem(from: account)
        }
    }

    func getActiveAccount() async throws -> ProfileSwitcherItem {
        let active = try await stateService.getActiveAccount()
        return await profileItem(from: active)
    }

    func getAccount(for userId: String) async throws -> Account {
        let accounts = try await stateService.getAccounts()
        guard let match = accounts.first(where: { account in
            account.profile.userId == userId
        }) else {
            throw StateServiceError.noAccounts
        }
        return match
    }

    func getFingerprintPhrase(userId _: String?) async throws -> String {
        let account = try await stateService.getActiveAccount()
        return try await clientPlatform.userFingerprint(fingerprintMaterial: account.profile.userId)
    }

    func initiateLoginWithDevice(deviceId: String, email: String) async throws -> String {
        let request = try await clientAuth.newAuthRequest(email: email)
        try await authService.initiateLoginWithDevice(
            accessCode: request.accessCode,
            deviceIdentifier: deviceId,
            email: email,
            fingerPrint: request.fingerprint,
            publicKey: request.publicKey
        )
        return request.fingerprint
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

    func setActiveAccount(userId: String) async throws -> Account {
        try await stateService.setActiveAccount(userId: userId)
        await environmentService.loadURLsForActiveAccount()
        return try await stateService.getActiveAccount()
    }

    func setPins(_ pin: String, requirePasswordAfterRestart: Bool) async throws {
        let pinKey = try await clientCrypto.derivePinKey(pin: pin)
        try await stateService.setPinKeys(
            pinKeyEncryptedUserKey: pinKey.encryptedPin,
            pinProtectedUserKey: pinKey.pinProtectedUserKey,
            requirePasswordAfterRestart: requirePasswordAfterRestart
        )
    }

    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws {
        // Ensure we have a user id.
        let id = try await userIdOrActive(userId)
        let currentValue = try? await vaultTimeoutService.sessionTimeoutValue(userId: id)
        // Set or delete the never lock key according to the current and new values.
        if case .never = value {
            try await keychainService.setUserAuthKey(
                for: .neverLock(
                    userId: id
                ),
                value: clientCrypto.getUserEncryptionKey()
            )
        } else if currentValue == .never {
            try await keychainService.deleteUserAuthKey(
                for: .neverLock(userId: id)
            )
        }

        // Then configure the vault timeout service with the correct value.
        try await vaultTimeoutService.setVaultTimeout(
            value: value,
            userId: id
        )
    }

    func unlockVaultWithBiometrics() async throws {
        let decryptedUserKey = try await biometricsRepository.getUserAuthKey()
        try await unlockVault(method: .decryptedKey(decryptedUserKey: decryptedUserKey))
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
        try await unlockVault(method: .password(password: password, userKey: encryptionKeys.encryptedUserKey))
    }

    func unlockVaultWithPIN(pin: String) async throws {
        guard let pinProtectedUserKey = try await stateService.pinProtectedUserKey() else {
            throw StateServiceError.noPinProtectedUserKey
        }
        try await unlockVault(method: .pin(pin: pin, pinProtectedUserKey: pinProtectedUserKey))
    }

    // MARK: Private

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
        return ProfileSwitcherItem(
            email: account.profile.email,
            isUnlocked: displayAsUnlocked,
            userId: account.profile.userId,
            userInitials: account.initials()
                ?? ".."
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

        await vaultTimeoutService.unlockVault(userId: account.profile.userId)
        try await organizationService.initializeOrganizationCrypto()
    }

    private func userIdOrActive(_ maybeId: String?) async throws -> String {
        if let maybeId { return maybeId }
        return try await stateService.getActiveAccountId()
    }
}
