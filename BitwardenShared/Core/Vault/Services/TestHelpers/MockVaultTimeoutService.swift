import Combine

@testable import BitwardenShared

class MockVaultTimeoutService: VaultTimeoutService {
    /// The store of locked status for known accounts
    var timeoutStore = [String: Bool]() {
        didSet {
            isLockedSubject.send(timeoutStore)
        }
    }

    lazy var isLockedSubject = CurrentValueSubject<[String: Bool], Never>(self.timeoutStore)

    func isLocked(userId: String) throws -> Bool {
        guard let pair = timeoutStore.first(where: { $0.key == userId }) else {
            throw VaultTimeoutServiceError.noAccountFound
        }
        return pair.value
    }

    func isLockedPublisher() -> AsyncPublisher<AnyPublisher<[String: Bool], Never>> {
        isLockedSubject.eraseToAnyPublisher().values
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
