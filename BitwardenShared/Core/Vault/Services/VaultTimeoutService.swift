import Combine

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

    /// Checks the locked status of a user vault by user id
    ///  - Parameter userId: The userId of the account
    ///  - Returns: A bool, true if locked, false if unlocked.
    ///
    func isLocked(userId: String) throws -> Bool

    /// Locks the user's vault
    ///
    /// - Parameter userId: The userId of the account to lock.
    ///     Defaults to the active account if nil
    ///
    func lockVault(userId: String?) async

    /// Unlocks the user's vault
    ///
    /// - Parameter userId: The userId of the account to unlock.
    ///     Defaults to the active account if nil
    ///
    func unlockVault(userId: String?) async

    /// Removes an account id.
    ///
    func remove(userId: String?) async
}

// MARK: - DefaultVaultTimeoutService

class DefaultVaultTimeoutService: VaultTimeoutService {
    // MARK: Properties

    /// A subject containing the active account id.
    var activeAccountIdSubject = CurrentValueSubject<String?, Never>(nil)

    /// The service used by this Default Service.
    private var stateService: StateService

    /// The store of locked status for known accounts
    var timeoutStore = [String: Bool]()

    /// A String to track the last known active account id.
    var lastKnownActiveAccountId: String?

    // MARK: Initialization

    /// Creates a new `DefaultVaultTimeoutService`.
    ///
    /// - Parameter stateService: The StateService used by DefaultVaultTimeoutService.
    ///
    init(stateService: StateService) {
        self.stateService = stateService
    }

    func isLocked(userId: String) throws -> Bool {
        guard let isLocked = timeoutStore[userId] else {
            throw VaultTimeoutServiceError.noAccountFound
        }
        return isLocked
    }

    func lockVault(userId: String?) async {
        guard let id = try? await stateService.getAccountIdOrActiveId(userId: userId) else { return }
        timeoutStore[id] = true
    }

    func unlockVault(userId: String?) async {
        guard let id = try? await stateService.getAccountIdOrActiveId(userId: userId) else { return }
        var updatedStore = timeoutStore.mapValues { _ in true }
        updatedStore[id] = false
        timeoutStore = updatedStore
    }

    func remove(userId: String?) async {
        guard let id = try? await stateService.getAccountIdOrActiveId(userId: userId) else { return }
        timeoutStore = timeoutStore.filter { $0.key != id }
    }
}
