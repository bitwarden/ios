import BitwardenSdk
import Combine
import Foundation

// MARK: - VaultTimeoutServiceError

/// The errors thrown from a `VaultTimeoutService`.
///
enum VaultTimeoutServiceError: Error {
    /// There are no known accounts.
    case noAccountFound

    /// An error for when saving an auth key to the keychain fails.
    ///
    case setAuthKeyFailed
}

// MARK: - VaultTimeoutService

/// A protocol for handling vault access.
///
protocol VaultTimeoutService: AnyObject {
    // MARK: Methods

    /// Whether a session timeout should occur.
    ///
    /// - Returns: Whether a session timeout should occur.
    ///
    func hasPassedSessionTimeout(userId: String) async throws -> Bool

    /// Checks the locked status of a user vault by user id
    ///  - Parameter userId: The userId of the account
    ///  - Returns: A bool, true if locked, false if unlocked.
    ///
    func isLocked(userId: String) -> Bool

    /// Locks the user's vault
    ///
    /// - Parameter userId: The userId of the account to lock.
    ///     Defaults to the active account if nil
    ///
    func lockVault(userId: String?) async

    /// Removes an account id.
    ///
    /// - Parameter userId: The user's ID.
    ///
    func remove(userId: String?) async

    /// Sets the last active time within the app.
    ///
    /// - Parameter userId: The user ID associated with the last active time within the app.
    ///
    func setLastActiveTime(userId: String) async throws

    /// Sets the session timeout date upon the app being backgrounded.
    ///
    /// - Parameters:
    ///   - value: The timeout value.
    ///   - userId: The user's ID.
    ///
    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws

    /// Unlocks the user's vault
    ///
    /// - Parameter userId: The userId of the account to unlock.
    ///     Defaults to the active account if nil
    ///
    func unlockVault(userId: String?) async throws

    /// Gets the `SessionTimeoutValue` for a user.
    ///
    ///  - Parameter userId: The userId of the account.
    ///     Defaults to the active user if nil.
    ///
    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue
}

// MARK: - DefaultVaultTimeoutService

class DefaultVaultTimeoutService: VaultTimeoutService {
    // MARK: Publishers

    /// A subject containing the active account id.
    var activeAccountIdSubject = CurrentValueSubject<String?, Never>(nil)

    // MARK: Private properties

    private var clientService: ClientService

    /// The state service used by this Default Service.
    private var stateService: StateService

    /// Provides the current time.
    private var timeProvider: TimeProvider

    // MARK: Initialization

    /// Creates a new `DefaultVaultTimeoutService`.
    ///
    /// - Parameters:
    ///   - clientCrypto: The client used by the application to handle encryption and decryption setup tasks.
    ///   - keychainRepository: The repository used to manages keychain items.
    ///   - stateService: The StateService used by DefaultVaultTimeoutService.
    ///   - timeProvider: Provides the current time.
    ///
    init(
        clientService: ClientService,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.clientService = clientService
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    func hasPassedSessionTimeout(userId: String) async throws -> Bool {
        guard let lastActiveTime = try await stateService.getLastActiveTime(userId: userId) else { return true }
        let vaultTimeout = try await sessionTimeoutValue(userId: userId)

        switch vaultTimeout {
        case .never,
             .onAppRestart:
            // For timeouts of `.never` or `.onAppRestart`, timeouts cannot be calculated.
            // In these cases, return false.
            return false
        default:
            // Otherwise, calculate a timeout.
            return timeProvider.presentTime.timeIntervalSince(lastActiveTime)
                >= TimeInterval(vaultTimeout.rawValue)
        }
    }

    func isLocked(userId: String) -> Bool {
        guard let client = clientService.userClientDictionary[userId], client.isUnlocked else {
            return true
        }
        return false
    }

    func lockVault(userId: String?) async {
        guard let id = try? await stateService.getAccountIdOrActiveId(userId: userId) else { return }
        clientService.userClientDictionary.removeValue(forKey: id)
    }

    func remove(userId: String?) async {
        guard let id = try? await stateService.getAccountIdOrActiveId(userId: userId) else { return }
        clientService.userClientDictionary.removeValue(forKey: id)
    }

    func setLastActiveTime(userId: String) async throws {
        try await stateService.setLastActiveTime(timeProvider.presentTime, userId: userId)
    }

    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws {
        try await stateService.setVaultTimeout(value: value, userId: userId)
    }

    func unlockVault(userId: String?) async throws {
        guard let id = try? await stateService.getAccountIdOrActiveId(userId: userId) else { return }
        guard let client = clientService.userClientDictionary[id] else { return }
        clientService.userClientDictionary.updateValue((client.client, true), forKey: id)
    }

    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue {
        try await stateService.getVaultTimeout(userId: userId)
    }
}
