import Combine
import Foundation

/// A protocol for a `SettingsRepository` which manages access to the data needed by the UI layer.
///
protocol SettingsRepository: AnyObject {
    /// Updates the user's vault by syncing it with the API.
    ///
    func fetchSync() async throws

    /// A publisher for the last sync time.
    ///
    /// - Returns: A publisher for the last sync time.
    ///
    func lastSyncTimePublisher() async throws -> AsyncPublisher<AnyPublisher<Date?, Never>>

    /// Locks the user's vault and clears decrypted data from memory.
    ///
    ///  - Parameter userId: The userId of the account to lock.
    ///     Defaults to active account if nil.
    ///
    func lockVault(userId: String?) async

    /// Logs the active user out of the application.
    ///
    func logout() async throws

    /// Unlocks the user's vault.
    ///
    ///  - Parameter userId: The userId of the account to unlock.
    ///     Defaults to active account if nil.
    ///
    func unlockVault(userId: String?) async
}

// MARK: - DefaultSettingsRepository

/// A default implementation of a `SettingsRepository`.
///
class DefaultSettingsRepository {
    // MARK: Properties

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The service used to handle syncing vault data with the API.
    let syncService: SyncService

    /// The service used to manage vault access.
    let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultSettingsRepository`.
    ///
    /// - Parameters:
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - vaultTimeoutService: The service used to manage vault access.
    ///
    init(
        stateService: StateService,
        syncService: SyncService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.stateService = stateService
        self.syncService = syncService
        self.vaultTimeoutService = vaultTimeoutService
    }
}

// MARK: - SettingsRepository

extension DefaultSettingsRepository: SettingsRepository {
    func fetchSync() async throws {
        try await syncService.fetchSync()
    }

    func lastSyncTimePublisher() async throws -> AsyncPublisher<AnyPublisher<Date?, Never>> {
        try await stateService.lastSyncTimePublisher().values
    }

    func lockVault(userId: String?) async {
        await vaultTimeoutService.lockVault(userId: userId)
    }

    func logout() async throws {
        try await stateService.logoutAccount()
    }

    func unlockVault(userId: String?) async {
        await vaultTimeoutService.unlockVault(userId: userId)
    }
}
