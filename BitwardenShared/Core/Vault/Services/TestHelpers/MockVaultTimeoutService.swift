import Combine
import Foundation

@testable import BitwardenShared

class MockVaultTimeoutService: VaultTimeoutService {
    var account: Account = .fixture()
    var client = MockClient()
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

    /// A dictionary that mapps the user ID to their client and it's locked status.
    var userClientDictionary = [String: (client: BitwardenSdkClient, isLocked: Bool)]()

    func isLocked(userId: String) -> Bool {
        guard let client = userClientDictionary[userId] else { return true }
        return client.isLocked
    }

    func lockVault(userId: String?) async {
        lockedIds.append(userId)
        guard let userId else { return }
        userClientDictionary.updateValue((client: client, isLocked: true), forKey: userId)
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
        userClientDictionary.updateValue((client: client, isLocked: false), forKey: userId)
    }

    func remove(userId: String?) async {
        removedIds.append(userId)
        guard let userId else { return }
        userClientDictionary.removeValue(forKey: userId)
    }

    func sessionTimeoutValue(userId: String?) async throws -> BitwardenShared.SessionTimeoutValue {
        if let sessionTimeoutValueError {
            throw sessionTimeoutValueError
        }
        return vaultTimeout[userId ?? account.profile.userId] ?? .fifteenMinutes
    }
}
