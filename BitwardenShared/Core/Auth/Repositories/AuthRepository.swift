import BitwardenSdk
import Foundation

/// A protocol for an `AuthRepository` which manages access to the data needed by the UI layer.
///
protocol AuthRepository: AnyObject {
    // MARK: Methods

    /// Deletes the user's account.
    ///
    /// - Parameter passwordText: The password entered by the user, which is used to verify
    /// their identify before deleting the account.
    ///
    func deleteAccount(passwordText: String) async throws

    /// Deletes the user Biometric auth key from the keychain.
    ///
    func deleteUserBiometricAuthKey() async throws

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
    func unlockVault(password: String) async throws

    /// Attempts to unlock the user's vault with biometrics.
    ///
    /// - Returns: A `Bool` indicating if the attempt was successful.
    ///
    func unlockVaultWithBiometrics() async throws -> Bool

    /// Stores the user auth key to the keychain.
    ///
    func storeUserBiometricAuthKey() async throws
}

// MARK: - DefaultAuthRepository

/// A default implementation of an `AuthRepository`.
///
class DefaultAuthRepository {
    // MARK: Properties

    /// The services used by the application to make account related API requests.
    let accountAPIService: AccountAPIService

    /// The service used that handles some of the auth logic.
    let authService: AuthService

    /// The service to use system Biometrics for vault unlock.
    let biometricsService: BiometricsService

    /// The client used by the application to handle auth related encryption and decryption tasks.
    let clientAuth: ClientAuthProtocol

    /// The client used by the application to handle encryption and decryption setup tasks.
    let clientCrypto: ClientCryptoProtocol

    /// The client used by the application to handle account fingerprint phrase generation.
    let clientPlatform: ClientPlatformProtocol

    /// The service used by the application to manage the environment settings.
    let environmentService: EnvironmentService

    /// The service used to manage syncing and updates to the user's organizations.
    let organizationService: OrganizationService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The service used by the application to manage vault access.
    let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultAuthRepository`.
    ///
    /// - Parameters:
    ///   - accountAPIService: The services used by the application to make account related API requests.
    ///   - authService: The service used that handles some of the auth logic.
    ///   - biometricsService: The service to use system Biometrics for vault unlock.
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
        biometricsService: BiometricsService,
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
        self.biometricsService = biometricsService
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
    func getFingerprintPhrase(userId: String?) async throws -> String {
        let account = try await stateService.getActiveAccount()
        return try await clientPlatform.userFingerprint(fingerprintMaterial: account.profile.userId)
    }

    func deleteAccount(passwordText: String) async throws {
        let hashedPassword = try await authService.hashPassword(password: passwordText, purpose: .serverAuthorization)

        _ = try await accountAPIService.deleteAccount(
            body: DeleteAccountRequestModel(masterPasswordHash: hashedPassword)
        )

        try await stateService.deleteAccount()
        await vaultTimeoutService.remove(userId: nil)
    }

    func deleteUserBiometricAuthKey() async throws {
        let userId = try await getActiveAccount().userId
        try await biometricsService.deleteUserAuthKey(for: userId)
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

    func unlockVault(password: String) async throws {
        let encryptionKeys = try await stateService.getAccountEncryptionKeys()
        let account = try await stateService.getActiveAccount()
        try await clientCrypto.initializeUserCrypto(
            req: InitUserCryptoRequest(
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                privateKey: encryptionKeys.encryptedPrivateKey,
                method: .password(
                    password: password,
                    userKey: encryptionKeys.encryptedUserKey
                )
            )
        )
        await vaultTimeoutService.unlockVault(userId: account.profile.userId)
        try await organizationService.initializeOrganizationCrypto()

        let hashedPassword = try await authService.hashPassword(password: password, purpose: .localAuthorization)
        try await stateService.setMasterPasswordHash(hashedPassword)
    }

    func unlockVaultWithBiometrics() async throws -> Bool {
        let encryptionKeys = try await stateService.getAccountEncryptionKeys()
        let account = try await stateService.getActiveAccount()
        guard let userKey = try await biometricsService
            .retrieveUserAuthKey(for: account.profile.userId),
            !userKey.isEmpty else {
            return false
        }
        try await clientCrypto.initializeUserCrypto(
            req: InitUserCryptoRequest(
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                privateKey: encryptionKeys.encryptedPrivateKey,
                method: .decryptedKey(decryptedUserKey: userKey)
            )
        )
        await vaultTimeoutService.unlockVault(userId: account.profile.userId)
        try await organizationService.initializeOrganizationCrypto()
        return true
    }

    /// A function to convert an `Account` to a `ProfileSwitcherItem`
    ///
    ///   - Parameter account: The account to convert.
    ///   - Returns: The `ProfileSwitcherItem` representing the account.
    ///
    func profileItem(from account: Account) async -> ProfileSwitcherItem {
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

    func storeUserBiometricAuthKey() async throws {
        let userId = try await getActiveAccount().userId
        let key = try await clientCrypto.getUserEncryptionKey()
        try await biometricsService.setUserAuthKey(value: key, for: userId)
    }
}
