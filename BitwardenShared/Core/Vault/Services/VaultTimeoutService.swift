import Combine

// MARK: - VaultTimeoutService

/// A protocol for handling vault access.
///
protocol VaultTimeoutService: AnyObject {
    // MARK: Methods

    /// Locks the user's vault.
    ///
    func lock()

    // MARK: Publishers

    /// A publisher for the vault locking functionality that publishes a `Bool` if the vault locks.
    ///
    /// - Returns: Whether or not the vault is locked.
    ///
    func isLockedPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>>
}

// MARK: - DefaultVaultTimeoutService

class DefaultVaultTimeoutService: VaultTimeoutService {
    /// A subject containing a `Bool` for whether or not the vault is locked.
    var isLockedSubject = CurrentValueSubject<Bool, Never>(false)

    func lock() {
        isLockedSubject.send(true)
    }

    func isLockedPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>> {
        isLockedSubject
            .eraseToAnyPublisher()
            .values
    }
}
