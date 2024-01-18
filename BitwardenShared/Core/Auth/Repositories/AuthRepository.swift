import BitwardenSdk
import Foundation

/// A protocol for an `AuthRepository` which manages access to the data needed by the UI layer.
///
protocol AuthRepository: AnyObject {
    // MARK: Methods

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
    func getFingerprintPhrase(userId: String?) async throws -> String

    /// Whether pin unlock is available.
    ///
    /// - Returns: Whether pin unlock is available.
    ///
    func isPinUnlockAvailable() async throws -> Bool

    /// Logs the user out of the active account.
    ///
    func logout() async throws

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

// MARK: - DefaultAuthRepository

/// A default implementation of an `AuthRepository`.
///
class DefaultAuthRepository {
    // MARK: Properties

    /// The services used by the application to make account related API requests.
    private let accountAPIService: AccountAPIService

    /// The service used that handles some of the auth logic.
    private let authService: AuthService

    /// The client used by the application to handle auth related encryption and decryption tasks.
    private let clientAuth: ClientAuthProtocol

    /// The client used by the application to handle encryption and decryption setup tasks.
    private let clientCrypto: ClientCryptoProtocol

    /// The client used by the application to handle account fingerprint phrase generation.
    let clientPlatform: ClientPlatformProtocol

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

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
    ///   - clientAuth: The client used by the application to handle auth related encryption and decryption tasks.
    ///   - clientCrypto: The client used by the application to handle encryption and decryption setup tasks.
    ///   - clientPlatform: The client used by the application to handle generating account fingerprints.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - organizationService: The service used to manage syncing and updates to the user's organizations.
    ///   - stateService: The service used by the application to manage account state.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        accountAPIService: AccountAPIService,
        authService: AuthService,
        clientAuth: ClientAuthProtocol,
        clientCrypto: ClientCryptoProtocol,
        clientPlatform: ClientPlatformProtocol,
        environmentService: EnvironmentService,
        organizationService: OrganizationService,
        stateService: StateService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.accountAPIService = accountAPIService
        self.authService = authService
        self.clientAuth = clientAuth
        self.clientCrypto = clientCrypto
        self.clientPlatform = clientPlatform
        self.environmentService = environmentService
        self.organizationService = organizationService
        self.stateService = stateService
        self.vaultTimeoutService = vaultTimeoutService
    }
}

// MARK: - AuthRepository

extension DefaultAuthRepository: AuthRepository {
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

    func getFingerprintPhrase(userId: String?) async throws -> String {
        let account = try await stateService.getActiveAccount()
        return try await clientPlatform.userFingerprint(fingerprintMaterial: account.profile.userId)
    }

    func isPinUnlockAvailable() async throws -> Bool {
        try await stateService.pinProtectedUserKey() != nil
    }

    func logout() async throws {
        await vaultTimeoutService.remove(userId: nil)
        try await stateService.logoutAccount()
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
            encryptedPin: pinKey.encryptedPin,
            pinProtectedUserKey: pinKey.pinProtectedUserKey,
            requirePasswordAfterRestart: requirePasswordAfterRestart
        )
    }

    func unlockVaultWithPassword(password: String) async throws {
        try await unlockVault(password, method: .password)
    }

    func unlockVaultWithPIN(pin: String) async throws {
        try await unlockVault(pin, method: .pin)
    }

    // MARK: Private

    /// A function to convert an `Account` to a `ProfileSwitcherItem`
    ///
    ///   - Parameter account: The account to convert.
    ///   - Returns: The `ProfileSwitcherItem` representing the account.
    ///
    private func profileItem(from account: Account) async -> ProfileSwitcherItem {
        var profile = ProfileSwitcherItem(
            email: account.profile.email,
            userId: account.profile.userId,
            userInitials: account.initials()
                ?? ".."
        )
        do {
            let isUnlocked = try !vaultTimeoutService.isLocked(userId: account.profile.userId)
            profile.isUnlocked = isUnlocked
            return profile
        } catch {
            profile.isUnlocked = false
            let userId = profile.userId
            await vaultTimeoutService.lockVault(userId: userId)
            return profile
        }
    }

    /// Unlocks the vault with the pin or password.
    ///
    /// - Parameters:
    ///   - passwordOrPin: The user's password or pin.
    ///   - method: The unlocking method, which is either password or pin.
    ///
    private func unlockVault(_ passwordOrPin: String, method: UnlockMethod) async throws {
        let account = try await stateService.getActiveAccount()
        let encryptionKeys = try await stateService.getAccountEncryptionKeys()

        switch method {
        case .password:
            try await clientCrypto.initializeUserCrypto(
                req: InitUserCryptoRequest(
                    kdfParams: account.kdf.sdkKdf,
                    email: account.profile.email,
                    privateKey: encryptionKeys.encryptedPrivateKey,
                    method: .password(
                        password: passwordOrPin,
                        userKey: encryptionKeys.encryptedUserKey
                    )
                )
            )
            let hashedPassword = try await authService.hashPassword(
                password: passwordOrPin,
                purpose: .localAuthorization
            )
            try await stateService.setMasterPasswordHash(hashedPassword)
        case .pin:
            guard let pinKeyEncryptedUserKey = try await stateService.pinKeyEncryptedUserKey() else {
                throw StateServiceError.noPinKeyEncryptedUserKey
            }
            try await clientCrypto.initializeUserCrypto(
                req: InitUserCryptoRequest(
                    kdfParams: account.kdf.sdkKdf,
                    email: account.profile.email,
                    privateKey: encryptionKeys.encryptedPrivateKey,
                    method: .pin(
                        pin: passwordOrPin,
                        pinProtectedUserKey: pinKeyEncryptedUserKey
                    )
                )
            )
        }
        await vaultTimeoutService.unlockVault(userId: account.profile.userId)
        try await organizationService.initializeOrganizationCrypto()
    }
}
