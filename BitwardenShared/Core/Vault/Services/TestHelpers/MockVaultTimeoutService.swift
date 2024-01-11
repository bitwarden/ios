import Combine
import Foundation

@testable import BitwardenShared

class MockVaultTimeoutService: VaultTimeoutService {
    var account: Account = .fixture()
    var dateProvider = MockDateProvider()
    var lastActiveTime = [String: Date]()
    var shouldClear = false
    var shouldSessionTimeout = [String: Bool]()
    var vaultTimeout = [String: Double?]()
    lazy var shouldClearSubject = CurrentValueSubject<Bool, Never>(self.shouldClear)

    /// ids set as locked
    var lockedIds = [String?]()

    /// ids removed
    var removedIds = [String?]()

    /// ids set as unlocked
    var unlockedIds = [String?]()

    /// The store of locked status for known accounts
    var timeoutStore = [String: Bool]() {
        didSet {
            shouldClearSubject.send(shouldClear)
        }
    }

    func isLocked(userId: String) throws -> Bool {
        guard let pair = timeoutStore.first(where: { $0.key == userId }) else {
            throw VaultTimeoutServiceError.noAccountFound
        }
        return pair.value
    }

    func lockVault(userId: String?) async {
        lockedIds.append(userId)
        guard let userId else { return }
        timeoutStore[userId] = true
    }

    func setLastActiveTime(userId: String) async throws {
        lastActiveTime[userId] = dateProvider.now
    }

    func setVaultTimeout(value: Double?, userId: String?) async throws {
        vaultTimeout[account.profile.userId] = value
    }

    func shouldClearDecryptedDataPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>> {
        shouldClearSubject
            .eraseToAnyPublisher()
            .values
    }

    func shouldSessionTimeout(userId: String) async throws -> Bool {
        shouldSessionTimeout[userId] ?? false
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
