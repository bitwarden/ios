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

    // MARK: Publishers

    /// A publisher for the vault locking functionality that publishes a `Bool` if the vault locks.
    ///
    /// - Returns: Whether or not the vault is locked.
    ///
    func isLockedPublisher() -> AsyncPublisher<AnyPublisher<[String: Bool], Never>>

    /// Removes an account id.
    ///
    func remove(userId: String?) async
}

// MARK: - DefaultVaultTimeoutService

class DefaultVaultTimeoutService: VaultTimeoutService {
    // MARK: Properties

    /// The services used by this Default Service.
    private var service: StateService

    /// The store of locked status for known accounts
    var timeoutStore = [String: Bool]() {
        didSet {
            isLockedSubject.send(timeoutStore)
        }
    }

    /// A subject containing a `Bool` for whether or not the vault is locked.
    lazy var isLockedSubject = CurrentValueSubject<[String: Bool], Never>(self.timeoutStore)

    // MARK: Initialization

    /// Creates a new `DefaultVaultTimeoutService`.
    ///
    /// - Parameter service: The StateService used by DefaultVaultTimeoutService.
    ///
    init(service: StateService) {
        self.service = service
    }

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

    func lockVault(userId: String?) async {
        if let userId {
            timeoutStore[userId] = true
        } else {
            guard let activeId = try? await service.getActiveAccount().profile.userId else { return }
            timeoutStore[activeId] = true
        }
    }

    func unlockVault(userId: String?) async {
        if let userId {
            timeoutStore[userId] = false
        } else {
            guard let activeId = try? await service.getActiveAccount().profile.userId else { return }
            timeoutStore[activeId] = false
        }
    }

    func remove(userId: String?) async {
        if let userId {
            timeoutStore = timeoutStore.filter { $0.key != userId }
        } else {
            guard let activeId = try? await service.getActiveAccount().profile.userId else { return }
            timeoutStore = timeoutStore.filter { $0.key != activeId }
        }
    }
}
