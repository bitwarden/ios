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
    ///
    func lockVault(userId: String)

    /// Unlocks the user's vault
    ///
    /// - Parameter userId: The userId of the account to unlock.
    ///
    func unlockVault(userId: String)

    // MARK: Publishers

    /// A publisher for the vault locking functionality that publishes a `Bool` if the vault locks.
    ///
    /// - Returns: Whether or not the vault is locked.
    ///
    func isLockedPublisher() -> AsyncPublisher<AnyPublisher<[String: Bool], Never>>

    /// Removes an account id.
    ///
    func remove(userId: String)
}

// MARK: - DefaultVaultTimeoutService

class DefaultVaultTimeoutService: VaultTimeoutService {
    /// The store of locked status for known accounts
    var timeoutStore = [String: Bool]() {
        didSet {
            isLockedSubject.send(timeoutStore)
        }
    }

    /// A subject containing a `Bool` for whether or not the vault is locked.
    lazy var isLockedSubject = CurrentValueSubject<[String: Bool], Never>(self.timeoutStore)

    func isLocked(userId: String) throws -> Bool {
        guard let pair = timeoutStore.first(where: { $0.key == userId }) else {
            throw VaultTimeoutServiceError.noAccountFound
        }
        return pair.value
    }

    func isLockedPublisher() -> AsyncPublisher<AnyPublisher<[String: Bool], Never>> {
        isLockedSubject
            .eraseToAnyPublisher()
            .values
    }

    func lockVault(userId: String) {
        timeoutStore[userId] = true
    }

    func unlockVault(userId: String) {
        timeoutStore[userId] = false
    }

    func remove(userId: String) {
        timeoutStore = timeoutStore.filter { $0.key != userId }
    }
}
