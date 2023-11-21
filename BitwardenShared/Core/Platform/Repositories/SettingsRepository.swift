/// A protocol for a `SettingsRepository` which manages access to the data needed by the UI layer.
///
protocol SettingsRepository: AnyObject {
    /// Locks the user's vault and clears decrypted data from memory.
    ///
    ///  - Parameter userId: The userId of the account to lock.
    ///     Defaults to active account if nil.
    ///
    func lockVault(userId: String?) async

    /// Unlocks the user's vault.
    ///
    ///  - Parameter userId: The userId of the account to unlock.
    ///     Defaults to active account if nil.
    ///
    func unlockVault(userId: String?) async

    /// Logs the active user out of the application.
    ///
    func logout() async throws
}

// MARK: - DefaultSettingsRepository

/// A default implementation of a `SettingsRepository`.
///
class DefaultSettingsRepository {
    // MARK: Properties

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The service used to manage vault access.
    let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultSettingsRepository`.
    ///
    /// - Parameters:
    ///   - stateService: The service used by the application to manage account state.
    ///   - vaultTimeoutService: The service used to manage vault access.
    ///
    init(
        stateService: StateService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.stateService = stateService
        self.vaultTimeoutService = vaultTimeoutService
    }
}

// MARK: - SettingsRepository

extension DefaultSettingsRepository: SettingsRepository {
    func lockVault(userId: String?) async {
        await vaultTimeoutService.lockVault(userId: userId)
    }

    func unlockVault(userId: String?) async {
        await vaultTimeoutService.unlockVault(userId: userId)
    }

    func logout() async throws {
        try await stateService.logoutAccount()
    }
}
