import Combine
import Foundation

@testable import BitwardenShared

class MockVaultTimeoutService: VaultTimeoutService {
    var account: Account = .fixture()
    var lastActiveTime = [String: Date]()
    var shouldSessionTimeout = [String: Bool]()
    var timeProvider = MockTimeProvider(.currentTime)
    var sessionTimeoutValueError: Error?
    var vaultTimeout = [String: SessionTimeoutValue]()

    /// ids set as locked
    var lockedIds = [String?]()

    /// ids removed
    var removedIds = [String?]()

    /// ids set as unlocked
    var unlockedIds = [String?]()

    /// The store of locked status for known accounts
    var timeoutStore = [String: Bool]()

    func isLocked(userId: String) -> Bool {
        guard let pair = timeoutStore.first(where: { $0.key == userId }) else {
            timeoutStore[userId] = true
            return true
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

    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws {
        vaultTimeout[account.profile.userId] = value
    }

    func hasPassedSessionTimeout(userId: String) async throws -> Bool {
        shouldSessionTimeout[userId] ?? false
    }

    func unlockVault(userId: String?) async throws {
        unlockedIds.append(userId)
        guard let userId else { return }
        timeoutStore[userId] = false
    }

    func remove(userId: String?) async {
        removedIds.append(userId)
        guard let userId else { return }
        timeoutStore = timeoutStore.filter { $0.key != userId }
    }

    func sessionTimeoutValue(userId: String?) async throws -> BitwardenShared.SessionTimeoutValue {
        if let sessionTimeoutValueError {
            throw sessionTimeoutValueError
        }
        return vaultTimeout[userId ?? account.profile.userId] ?? .fifteenMinutes
    }
}
