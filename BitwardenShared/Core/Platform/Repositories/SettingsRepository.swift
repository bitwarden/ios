/// A protocol for a `SettingsRepository` which manages access to the data needed by the UI layer.
///
protocol SettingsRepository: AnyObject {
    /// Checks the locked status of a user vault by user id
    ///
    ///  - Parameter userId: The userId of the account
    ///  - Returns: A bool, true if locked, false if unlocked.
    ///
    func isLocked(userId: String) throws -> Bool

    /// Locks the user's vault and clears decrypted data from memory.
    ///
    ///  - Parameters:
    ///   - shouldLock: The lock status of the account.
    ///   - userId: The userId of the account to lock.
    ///
    func lockVault(_ shouldLock: Bool, userId: String)

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
    func isLocked(userId: String) throws -> Bool {
        try vaultTimeoutService.isLocked(userId: userId)
    }

    func lockVault(_ shouldLock: Bool, userId: String) {
        vaultTimeoutService.lockVault(shouldLock, userId: userId)
    }

    func logout() async throws {
        try await stateService.logoutAccount()
    }
}
