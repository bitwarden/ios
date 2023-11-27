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
    /// - Parameter userId: The user Id to be mapped to an account.
    /// - Returns: The user account.
    ///
    func getAccount(for userId: String) async throws -> Account

    /// Logs the user out of the active account.
    ///
    func logout() async throws

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

    // MARK: Initialization

    /// Initialize a `DefaultAuthRepository`.
    ///
    /// - Parameters:
    ///   - clientCrypto: The client used by the application to handle encryption and decryption setup tasks.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        clientCrypto: ClientCryptoProtocol,
        stateService: StateService
    ) {
        self.clientCrypto = clientCrypto
        self.stateService = stateService
    }
}

// MARK: - AuthRepository

extension DefaultAuthRepository: AuthRepository {
    func getAccounts() async throws -> [ProfileSwitcherItem] {
        let accounts = try await stateService.getAccounts()
        return accounts.map { account in
            profileItem(from: account)
        }
    }

    func getActiveAccount() async throws -> ProfileSwitcherItem {
        let active = try await stateService.getActiveAccount()
        return profileItem(from: active)
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
        try await stateService.logoutAccount()
    }

    func unlockVault(password: String) async throws {
        let encryptionKeys = try await stateService.getAccountEncryptionKeys()
        let account = try await stateService.getActiveAccount()
        try await clientCrypto.initializeCrypto(
            req: InitCryptoRequest(
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                password: password,
                userKey: encryptionKeys.encryptedUserKey,
                privateKey: encryptionKeys.encryptedPrivateKey,
                organizationKeys: [:]
            )
        )
    }

    /// A function to convert an `Account` to a `ProfileSwitcherItem`
    ///
    ///   - Parameter account: The account to convert
    ///   - Returns: The `ProfileSwitcherItem` representing the account
    ///
    func profileItem(from account: Account) -> ProfileSwitcherItem {
        ProfileSwitcherItem(
            email: account.profile.email,
            userId: account.profile.userId,
            userInitials: account.initials()
                ?? ".."
        )
    }
}
