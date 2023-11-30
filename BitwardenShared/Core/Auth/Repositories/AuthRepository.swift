import BitwardenSdk
import Foundation

/// A protocol for an `AuthRepository` which manages access to the data needed by the UI layer.
///
protocol AuthRepository: AnyObject {
    // MARK: Methods

    /// Gets the account for a given userId.
    ///
    /// - Parameter userId: The user Id to be mapped to an account.
    /// - Returns: The user account.
    ///
    func getAccount(for userId: String?) async throws -> Account

    /// Supplies a current Profile Switcher State.
    ///
    ///  - Parameters:
    ///     - visible: The visibility of the state.
    ///     - shouldAlwaysHideAddAccount:Overrides the visibilty of the add account row if true.
    ///  - Returns: An updated ProfileSwitcherState.
    ///
    @discardableResult
    func getProfileSwitcherState(visible: Bool, shouldAlwaysHideAddAccount: Bool) async -> ProfileSwitcherState

    /// Locks the user's vault and clears decrypted data from memory.
    ///
    ///  - Parameters:
    ///     - userId: The userId of the account to lock.
    ///     Defaults to active account if nil.
    ///     - state: A ProfileSwitcherState to update.
    ///  - Returns: An updated ProfileSwitcherState, if supplied.
    ///
    @discardableResult
    func lockVault(userId: String?, state: ProfileSwitcherState?) async -> ProfileSwitcherState?

    /// Logs the active user out of the application.
    ///
    ///  - Parameters:
    ///     - userId: The userId of the account to unlock.
    ///     Defaults to active account if nil.
    ///     - state: A ProfileSwitcherState to update.
    ///  - Returns: An updated ProfileSwitcherState, if supplied.
    ///
    @discardableResult
    func logout(userId: String?, state: ProfileSwitcherState?) async throws -> ProfileSwitcherState?

    /// Sets the active account by User Id.
    ///
    /// - Parameters:
    ///    - userId: The user Id to be set as active.
    ///    - state: A ProfileSwitcherState to update.
    /// - Returns: An updated ProfileSwitcherState, if supplied.
    @discardableResult
    func setActiveAccount(userId: String, state: ProfileSwitcherState?) async throws -> ProfileSwitcherState?

    /// Unlocks the user's vault.
    ///
    ///  - Parameters:
    ///     - password: The user's master password to unlock the vault.
    ///     - state: A ProfileSwitcherState to update.
    ///  - Returns: An updated ProfileSwitcherState, if supplied.
    ///
    @discardableResult
    func unlockVault(password: String, state: ProfileSwitcherState?) async throws -> ProfileSwitcherState?
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
    func getAccount(for userId: String?) async throws -> Account {
        let accounts = try await stateService.getAccounts()
        guard let match = accounts.first(where: { account in
            account.profile.userId == userId
        }) else {
            throw StateServiceError.noAccounts
        }
        return match
    }

    func getProfileSwitcherState(
        visible: Bool,
        shouldAlwaysHideAddAccount: Bool = false
    ) async -> ProfileSwitcherState {
        var accounts = [ProfileSwitcherItem]()
        var activeAccount: ProfileSwitcherItem?
        do {
            accounts = try await getAccounts()
            activeAccount = try? await getActiveAccount()
            return ProfileSwitcherState(
                accounts: accounts,
                activeAccountId: activeAccount?.userId,
                isVisible: visible,
                shouldAlwaysHideAddAccount: shouldAlwaysHideAddAccount
            )
        } catch {
            return ProfileSwitcherState.empty()
        }
    }

    func lockVault(userId: String?, state: ProfileSwitcherState? = nil) async -> ProfileSwitcherState? {
        await vaultTimeoutService.lockVault(userId: userId)
        guard let state else { return nil }
        return await getProfileSwitcherState(
            visible: state.isVisible,
            shouldAlwaysHideAddAccount: state.shouldAlwaysHideAddAccount
        )
    }

    func logout(userId: String?, state: ProfileSwitcherState? = nil) async throws -> ProfileSwitcherState? {
        await vaultTimeoutService.remove(userId: nil)
        try await stateService.logoutAccount(userId: userId)
        guard let state else { return nil }
        return await getProfileSwitcherState(
            visible: state.isVisible,
            shouldAlwaysHideAddAccount: state.shouldAlwaysHideAddAccount
        )
    }

    func setActiveAccount(userId: String, state: ProfileSwitcherState? = nil) async throws -> ProfileSwitcherState? {
        try await stateService.setActiveAccount(userId: userId)
        guard let state else { return nil }
        return await getProfileSwitcherState(
            visible: state.isVisible,
            shouldAlwaysHideAddAccount: state.shouldAlwaysHideAddAccount
        )
    }

    func unlockVault(
        password: String,
        state: ProfileSwitcherState? = nil
    ) async throws -> ProfileSwitcherState? {
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
        await vaultTimeoutService.unlockVault(userId: account.profile.userId)
        guard let state else { return nil }
        return await getProfileSwitcherState(
            visible: state.isVisible,
            shouldAlwaysHideAddAccount: state.shouldAlwaysHideAddAccount
        )
    }

    // MARK: Private Methods

    private func getAccounts() async throws -> [ProfileSwitcherItem] {
        let accounts = try await stateService.getAccounts()
        return await accounts.asyncMap { account in
            await account.profileItem(vaultTimeoutService: vaultTimeoutService)
        }
    }

    private func getActiveAccount() async throws -> ProfileSwitcherItem {
        let active = try await stateService.getActiveAccount()
        return await active.profileItem(vaultTimeoutService: vaultTimeoutService)
    }
}
