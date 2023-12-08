import BitwardenSdk
import Foundation

/// A protocol for an `AuthRepository` which manages access to the data needed by the UI layer.
///
protocol AuthRepository: AnyObject {
    // MARK: Methods

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

    /// Logs the user out of the active account.
    ///
    func logout() async throws

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
}

// MARK: - DefaultAuthRepository

/// A default implementation of an `AuthRepository`.
///
class DefaultAuthRepository {
    // MARK: Properties

    /// The client used by the application to handle encryption and decryption setup tasks.
    let clientCrypto: ClientCryptoProtocol

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The service used by the application to manage vault access.
    let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultAuthRepository`.
    ///
    /// - Parameters:
    ///   - clientCrypto: The client used by the application to handle encryption and decryption setup tasks.
    ///   - stateService: The service used by the application to manage account state.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        clientCrypto: ClientCryptoProtocol,
        stateService: StateService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.clientCrypto = clientCrypto
        self.stateService = stateService
        self.vaultTimeoutService = vaultTimeoutService
    }
}

// MARK: - AuthRepository

extension DefaultAuthRepository: AuthRepository {
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

    func setActiveAccount(userId: String) async throws -> Account {
        try await stateService.setActiveAccount(userId: userId)
        _ = try await stateService.getAccounts()
            .compactMap { account in
                let id = account.profile.userId
                return (id != userId) ? id : nil
            }
            .asyncMap { id in
                await vaultTimeoutService.lockVault(userId: id)
            }
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
}
