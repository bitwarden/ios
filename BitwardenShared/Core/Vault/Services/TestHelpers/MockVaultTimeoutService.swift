import Combine
import Foundation

@testable import BitwardenShared

class MockVaultTimeoutService: VaultTimeoutService {
    var account: Account = .fixture()
    var lastActiveTime = [String: Date]()
    var shouldSessionTimeout = [String: Bool]()
    var timeProvider = MockTimeProvider(.currentTime)
    var vaultTimeout = [String: Int?]()

    /// ids set as locked
    var lockedIds = [String?]()

    /// ids removed
    var removedIds = [String?]()

    /// ids set as unlocked
    var unlockedIds = [String?]()

    /// The store of locked status for known accounts
    var timeoutStore = [String: Bool]()

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
        lastActiveTime[userId] = timeProvider.presentTime
    }

    func setVaultTimeout(value: Int?, userId: String?) async throws {
        vaultTimeout[account.profile.userId] = value
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
