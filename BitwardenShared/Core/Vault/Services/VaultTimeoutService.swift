import AuthenticatorBridgeKit
import BitwardenKit
import BitwardenSdk
import Combine
import Foundation

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
@MainActor
protocol VaultTimeoutService: AnyObject {
    // MARK: Methods

    /// Whether a session timeout should occur.
    ///
    /// - Parameters:
    ///   - userId: The user ID to check.
    ///   - isAppRestart: Whether the app has been restarted and is checking timeouts on app startup.
    ///     Defaults to false.
    /// - Returns: Whether a session timeout should occur.
    ///
    func hasPassedSessionTimeout(userId: String, isAppRestart: Bool) async throws -> Bool

    /// Checks the locked status of a user vault by user id
    ///  - Parameter userId: The userId of the account
    ///  - Returns: A bool, true if locked, false if unlocked.
    ///
    func isLocked(userId: String) -> Bool

    /// Whether pin unlock is available for a userId.
    ///  - Parameter userId: The userId of the account.
    ///  - Returns: Whether pin unlock is available.
    ///
    func isPinUnlockAvailable(userId: String?) async throws -> Bool

    /// Locks the user's vault
    ///
    /// - Parameter userId: The userId of the account to lock.
    ///     Defaults to the active account if nil
    ///
    func lockVault(userId: String?) async

    /// Removes an account id.
    ///
    /// - Parameter userId: The user's ID.
    ///
    func remove(userId: String?) async

    /// Gets the `SessionTimeoutAction` for a user.
    ///
    ///  - Parameter userId: The userId of the account. Defaults to the active user if nil.
    ///
    func sessionTimeoutAction(userId: String?) async throws -> SessionTimeoutAction

    /// Gets the `SessionTimeoutValue` for a user.
    ///
    ///  - Parameter userId: The userId of the account.
    ///     Defaults to the active user if nil.
    ///
    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue

    /// Sets the last active time within the app.
    ///
    /// - Parameter userId: The user ID associated with the last active time within the app.
    ///
    func setLastActiveTime(userId: String) async throws

    /// Sets the session timeout date upon the app being backgrounded.
    ///
    /// - Parameters:
    ///   - value: The timeout value.
    ///   - userId: The user's ID.
    ///
    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws

    /// Unlocks the user's vault
    ///
    /// - Parameters:
    ///   - userId: The userId of the account to unlock.
    ///     Defaults to the active account if nil
    ///   - hadUserInteraction: Whether the user had any interaction with the app to unlock the vault
    ///   or the never lock key was used.
    func unlockVault(userId: String?, hadUserInteraction: Bool) async throws

    /// A publisher containing the active user ID and whether their vault is locked.
    ///
    /// - Returns: A publisher for the active user ID whether their vault is locked.
    ///
    func vaultLockStatusPublisher() async -> AnyPublisher<VaultLockStatus?, Never>
}

// MARK: - VaultTimeoutService Extensions

extension VaultTimeoutService {
    /// Whether a session timeout should occur.
    ///
    /// - Parameter userId: The user ID to check.
    /// - Returns: Whether a session timeout should occur.
    ///
    func hasPassedSessionTimeout(userId: String) async throws -> Bool {
        try await hasPassedSessionTimeout(userId: userId, isAppRestart: false)
    }
}

// MARK: - DefaultVaultTimeoutService

class DefaultVaultTimeoutService: VaultTimeoutService {
    // MARK: Private properties

    /// The service to use system biometrics for vault unlock.
    private let biometricsRepository: BiometricsRepository

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// A service that manages account timeout between apps.
    private let sharedTimeoutService: SharedTimeoutService

    /// The state service used by this Default Service.
    private let stateService: StateService

    /// Provides the current time.
    private let timeProvider: TimeProvider

    /// A subject containing the user's vault locked status mapped to their user ID.
    private let vaultLockStatusSubject = CurrentValueSubject<[String: Bool], Never>([:])

    // MARK: Initialization

    /// Creates a new `DefaultVaultTimeoutService`.
    ///
    /// - Parameters:
    ///   - biometricsRepository: The service to use system biometrics for vault unlock.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - sharedTimeoutService: The service that manages account timeout between apps.
    ///   - stateService: The StateService used by DefaultVaultTimeoutService.
    ///   - timeProvider: Provides the current time.
    ///
    init(
        biometricsRepository: BiometricsRepository,
        clientService: ClientService,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        sharedTimeoutService: SharedTimeoutService,
        stateService: StateService,
        timeProvider: TimeProvider,
    ) {
        self.biometricsRepository = biometricsRepository
        self.clientService = clientService
        self.configService = configService
        self.errorReporter = errorReporter
        self.sharedTimeoutService = sharedTimeoutService
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    func hasPassedSessionTimeout(userId: String, isAppRestart: Bool = false) async throws -> Bool {
        let vaultTimeout = try await sessionTimeoutValue(userId: userId)
        switch vaultTimeout {
        case .never:
            return false
        case .onAppRestart:
            // On app restart, trigger timeout if this is actually an app restart
            return isAppRestart
        default:
            // Otherwise, calculate a timeout.
            guard let lastActiveTime = try await stateService.getLastActiveTime(userId: userId)
            else { return true }

            return timeProvider.presentTime.timeIntervalSince(lastActiveTime)
                >= TimeInterval(vaultTimeout.seconds)
        }
    }

    func isLocked(userId: String) -> Bool {
        guard let isLocked = vaultLockStatusSubject.value[userId] else { return true }
        return isLocked
    }

    func isPinUnlockAvailable(userId: String?) async throws -> Bool {
        let hasPinProtectedUserKeyEnvelope = try await stateService.pinProtectedUserKeyEnvelope(userId: userId) != nil
        let hasPinProtectedUserKey = try await stateService.pinProtectedUserKey(userId: userId) != nil
        return hasPinProtectedUserKeyEnvelope || hasPinProtectedUserKey
    }

    func lockVault(userId: String?) async {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            vaultLockStatusSubject.value[userId] = true
            try await clientService.removeClient(for: userId)
            try await stateService.setAccountHasBeenUnlockedInteractively(userId: userId, value: false)
        } catch {
            errorReporter.log(error: error)
        }
    }

    func remove(userId: String?) async {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            vaultLockStatusSubject.value.removeValue(forKey: userId)
            try await clientService.removeClient(for: userId)
            try await stateService.setAccountHasBeenUnlockedInteractively(userId: userId, value: false)
        } catch {
            errorReporter.log(error: error)
        }
    }

    func sessionTimeoutAction(userId: String?) async throws -> SessionTimeoutAction {
        let hasMasterPassword = try await stateService.getUserHasMasterPassword(userId: userId)
        let timeoutAction = try await stateService.getTimeoutAction(userId: userId)
        guard hasMasterPassword else {
            let isBiometricsEnabled = try await biometricsRepository.getBiometricUnlockStatus(userId: userId).isEnabled
            let isPinEnabled = try await isPinUnlockAvailable(userId: userId)
            if isPinEnabled || isBiometricsEnabled {
                return timeoutAction
            } else {
                // If the user doesn't have a master password and hasn't enabled a pin or
                // biometrics, their timeout action needs to be logout.
                try await stateService.setTimeoutAction(action: .logout, userId: userId)
                return .logout
            }
        }
        return timeoutAction
    }

    func setLastActiveTime(userId: String) async throws {
        let now = timeProvider.presentTime
        try await stateService.setLastActiveTime(now, userId: userId)
        let vaultTimeout = try await sessionTimeoutValue(userId: userId)
        try await updateSharedTimeout(
            lastActiveTime: now,
            timeoutValue: vaultTimeout,
            userId: userId,
        )
    }

    func setVaultTimeout(value: SessionTimeoutValue, userId: String?) async throws {
        try await stateService.setVaultTimeout(value: value, userId: userId)
        guard let userId else { return }
        let lastActiveTime = try await stateService.getLastActiveTime(userId: userId)
        try await updateSharedTimeout(
            lastActiveTime: lastActiveTime,
            timeoutValue: value,
            userId: userId,
        )
    }

    func unlockVault(userId: String?, hadUserInteraction: Bool) async throws {
        guard let id = try? await stateService.getAccountIdOrActiveId(userId: userId) else { return }
        vaultLockStatusSubject.value[id] = false
        try await stateService.setAccountHasBeenUnlockedInteractively(userId: id, value: hadUserInteraction)
    }

    func sessionTimeoutValue(userId: String?) async throws -> SessionTimeoutValue {
        try await stateService.getVaultTimeout(userId: userId)
    }

    func vaultLockStatusPublisher() async -> AnyPublisher<VaultLockStatus?, Never> {
        await stateService.activeAccountIdPublisher()
            .combineLatest(vaultLockStatusSubject)
            .map { activeAccountId, lockStatusByAccount in
                guard let activeAccountId else { return nil }
                return VaultLockStatus(
                    isVaultLocked: lockStatusByAccount[activeAccountId] ?? true,
                    userId: activeAccountId,
                )
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Updates the shared timeout value in the SharedTimeoutService, so that BWA can log users out
    /// on timeout. In the event that the user should not be automatically logged out after a time,
    /// it will clear the timeout value.
    private func updateSharedTimeout(
        lastActiveTime: Date?,
        timeoutValue: SessionTimeoutValue,
        userId: String,
    ) async throws {
        let vaultTimeout = try await sessionTimeoutValue(userId: userId)
        switch vaultTimeout {
        case .never,
             .onAppRestart:
            // For timeouts of `.never` or `.onAppRestart`, timeouts cannot be calculated.
            // Therefore we can't have one saved.
            try await sharedTimeoutService.clearTimeout(forUserId: userId)
        default:
            let timeoutAction = try await sessionTimeoutAction(userId: userId)
            switch timeoutAction {
            case .lock:
                try await sharedTimeoutService.clearTimeout(forUserId: userId)
            case .logout:
                try await sharedTimeoutService.updateTimeout(
                    forUserId: userId,
                    lastActiveDate: lastActiveTime,
                    timeoutLength: timeoutValue,
                )
            }
        }
    }
}
