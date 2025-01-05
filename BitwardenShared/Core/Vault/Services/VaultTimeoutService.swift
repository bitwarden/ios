import BitwardenSdk
import Combine
import Foundation

// MARK: - VaultTimeoutServiceError

/// The errors thrown from a `VaultTimeoutService`.
///
enum VaultTimeoutServiceError: Error {
    /// There are no known accounts.
    case noAccountFound
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
    /// - Parameters:
    ///   - userId: The userId of the account to unlock.
    ///     Defaults to the active account if nil
    ///   - hadUserInteraction: Whether the user had any interaction with the app to unlock the vault
    ///   or the never lock key was used.
    func unlockVault(userId: String?, hadUserInteraction: Bool) async throws

    /// Gets the `SessionTimeoutValue` for a user.
    ///
    ///  - Parameter userId: The userId of the account.
    ///     Defaults to the active user if nil.
    ///
    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue

    /// A publisher containing the active user ID and whether their vault is locked.
    ///
    /// - Returns: A publisher for the active user ID whether their vault is locked.
    ///
    func vaultLockStatusPublisher() async -> AnyPublisher<VaultLockStatus?, Never>
}

// MARK: - DefaultVaultTimeoutService

class DefaultVaultTimeoutService: VaultTimeoutService {
    // MARK: Private properties

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The state service used by this Default Service.
    private let stateService: StateService

    /// Provides the current time.
    private let timeProvider: TimeProvider

    /// A subject containing the user's vault locked status mapped to their user ID.
    private let vaultLockStatusSubject = CurrentValueSubject<[String: Bool], Never>([:])

    // MARK: Initialization

    /// Creates a new `DefaultVaultTimeoutService`.
    ///
    /// - Parameters:
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The StateService used by DefaultVaultTimeoutService.
    ///   - timeProvider: Provides the current time.
    ///
    init(
        clientService: ClientService,
        errorReporter: ErrorReporter,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    func hasPassedSessionTimeout(userId: String) async throws -> Bool {
        let vaultTimeout = try await sessionTimeoutValue(userId: userId)
        switch vaultTimeout {
        case .never,
             .onAppRestart:
            // For timeouts of `.never` or `.onAppRestart`, timeouts cannot be calculated.
            // In these cases, return false.
            return false
        default:
            // Otherwise, calculate a timeout.
            guard let lastActiveTime = try await stateService.getLastActiveTime(userId: userId)
            else { return true }

            return timeProvider.presentTime.timeIntervalSince(lastActiveTime)
                >= TimeInterval(vaultTimeout.seconds)
        }
    }

    func isLocked(userId: String) -> Bool {
        guard let isLocked = vaultLockStatusSubject.value[userId] else { return true }
        return isLocked
    }

    func lockVault(userId: String?) async {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            vaultLockStatusSubject.value[userId] = true
            try await clientService.removeClient(for: userId)
            try await stateService.setAccountHasBeenUnlockedInteractively(userId: userId, value: false)
        } catch {
            errorReporter.log(error: error)
        }
    }

    func remove(userId: String?) async {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            vaultLockStatusSubject.value.removeValue(forKey: userId)
            try await clientService.removeClient(for: userId)
            try await stateService.setAccountHasBeenUnlockedInteractively(userId: userId, value: false)
        } catch {
            errorReporter.log(error: error)
        }
    }

    func setLastActiveTime(userId: String) async throws {
        try await stateService.setLastActiveTime(timeProvider.presentTime, userId: userId)
    }

    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws {
        try await stateService.setVaultTimeout(value: value, userId: userId)
    }

    func unlockVault(userId: String?, hadUserInteraction: Bool) async throws {
        guard let id = try? await stateService.getAccountIdOrActiveId(userId: userId) else { return }
        vaultLockStatusSubject.value[id] = false
        try await stateService.setAccountHasBeenUnlockedInteractively(userId: id, value: hadUserInteraction)
    }

    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue {
        try await stateService.getVaultTimeout(userId: userId)
    }

    func vaultLockStatusPublisher() async -> AnyPublisher<VaultLockStatus?, Never> {
        await stateService.activeAccountIdPublisher()
            .combineLatest(vaultLockStatusSubject)
            .map { activeAccountId, lockStatusByAccount in
                guard let activeAccountId else { return nil }
                return VaultLockStatus(
                    isVaultLocked: lockStatusByAccount[activeAccountId] ?? true,
                    userId: activeAccountId
                )
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
