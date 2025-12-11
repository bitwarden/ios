import BitwardenKit
import BitwardenKitMocks
import Combine
import Foundation

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class MockVaultTimeoutService: VaultTimeoutService {
    var account: Account = .fixture()
    var lastActiveTime = [String: Date]()
    var pinUnlockAvailabilityResult: Result<[String: Bool], Error> = .success([:])
    var setLastActiveTimeError: Error?
    var shouldSessionTimeout = [String: Bool]()
    var shouldSessionTimeoutError: Error?
    var timeProvider = MockTimeProvider(.currentTime)
    var sessionTimeoutAction = [String: SessionTimeoutAction]()
    var sessionTimeoutActionError: Error?
    var sessionTimeoutValueError: Error?
    var unlockVaultHadUserInteraction = false
    var vaultTimeout = [String: SessionTimeoutValue]()
    var vaultLockStatusSubject = CurrentValueSubject<VaultLockStatus?, Never>(nil)

    /// IDs removed.
    var removedIds = [String?]()

    /// Whether or not a user's client is locked.
    var isClientLocked = [String: Bool]()

    nonisolated init() {}

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

    func isPinUnlockAvailable(userId: String?) async throws -> Bool {
        guard let userId else { throw StateServiceError.noActiveAccount }

        return try pinUnlockAvailabilityResult.get()[userId] ?? false
    }

    func hasPassedSessionTimeout(userId: String) async throws -> Bool {
        if let shouldSessionTimeoutError {
            throw shouldSessionTimeoutError
        }
        return shouldSessionTimeout[userId] ?? false
    }

    func remove(userId: String?) async {
        removedIds.append(userId)
    }

    func sessionTimeoutAction(userId: String?) async throws -> SessionTimeoutAction {
        if let sessionTimeoutActionError {
            throw sessionTimeoutActionError
        }
        return sessionTimeoutAction[userId ?? account.profile.userId] ?? .lock
    }

    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue {
        if let sessionTimeoutValueError {
            throw sessionTimeoutValueError
        }
        return vaultTimeout[userId ?? account.profile.userId] ?? .fifteenMinutes
    }

    func unlockVault(userId: String?, hadUserInteraction: Bool) async throws {
        guard let userId else { return }
        isClientLocked[userId] = false
        unlockVaultHadUserInteraction = hadUserInteraction
    }

    func vaultLockStatusPublisher() async -> AnyPublisher<VaultLockStatus?, Never> {
        vaultLockStatusSubject.eraseToAnyPublisher()
    }
}
