import Combine

@testable import BitwardenShared

class MockVaultTimeoutService: VaultTimeoutService {
    /// The store of locked status for known accounts
    var timeoutStore = [String: Bool]() {
        didSet {
            shouldClearSubject.send(shouldClear)
        }
    }

    /// ids set as locked
    var lockedIds = [String?]()

    /// ids removed
    var removedIds = [String?]()

    /// ids set as unlocked
    var unlockedIds = [String?]()

    var shouldClear = false

    lazy var shouldClearSubject = CurrentValueSubject<Bool, Never>(self.shouldClear)

    func isLocked(userId: String) throws -> Bool {
        guard let pair = timeoutStore.first(where: { $0.key == userId }) else {
            throw VaultTimeoutServiceError.noAccountFound
        }
        return pair.value
    }

    func shouldClearDecryptedDataPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>> {
        shouldClearSubject
            .eraseToAnyPublisher()
            .values
    }

    func lockVault(userId: String?) async {
        lockedIds.append(userId)
        guard let userId else { return }
        timeoutStore[userId] = true
    }

    func unlockVault(userId: String?) async {
        unlockedIds.append(userId)
        guard let userId else { return }
        timeoutStore[userId] = false
    }

    func remove(userId: String?) async {
        removedIds.append(userId)
        guard let userId else { return }
        timeoutStore = timeoutStore.filter { $0.key != userId }
    }
}
