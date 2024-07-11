import Combine
import Foundation

@testable import BitwardenShared

class MockVaultTimeoutService: VaultTimeoutService {
    var account: Account = .fixture()
    var lastActiveTime = [String: Date]()
    var setLastActiveTimeError: Error?
    var shouldSessionTimeout = [String: Bool]()
    var shouldSessionTimeoutError: Error?
    var timeProvider = MockTimeProvider(.currentTime)
    var sessionTimeoutValueError: Error?
    var vaultTimeout = [String: SessionTimeoutValue]()
    var vaultLockStatusSubject = CurrentValueSubject<VaultLockStatus?, Never>(nil)

    /// IDs removed.
    var removedIds = [String?]()

    /// Whether or not a user's client is locked.
    var isClientLocked = [String: Bool]()

    func isLocked(userId: String) -> Bool {
        isClientLocked[userId] == true
    }

    func lockVault(userId: String?) async {
        guard let userId else { return }
        isClientLocked[userId] = true
    }

    func setLastActiveTime(userId: String) async throws {
        if let setLastActiveTimeError {
            throw setLastActiveTimeError
        }
        lastActiveTime[userId] = timeProvider.presentTime
    }

    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws {
        vaultTimeout[account.profile.userId] = value
    }

    func hasPassedSessionTimeout(userId: String) async throws -> Bool {
        if let shouldSessionTimeoutError {
            throw shouldSessionTimeoutError
        }
        return shouldSessionTimeout[userId] ?? false
    }

    func unlockVault(userId: String?) async throws {
        guard let userId else { return }
        isClientLocked[userId] = false
    }

    func remove(userId: String?) async {
        removedIds.append(userId)
    }

    func sessionTimeoutValue(userId: String?) async throws -> BitwardenShared.SessionTimeoutValue {
        if let sessionTimeoutValueError {
            throw sessionTimeoutValueError
        }
        return vaultTimeout[userId ?? account.profile.userId] ?? .fifteenMinutes
    }

    func vaultLockStatusPublisher() async -> AnyPublisher<VaultLockStatus?, Never> {
        vaultLockStatusSubject.eraseToAnyPublisher()
    }
}
