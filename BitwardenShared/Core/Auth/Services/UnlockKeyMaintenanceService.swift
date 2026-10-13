import BitwardenKit
import LocalAuthentication

// MARK: - UnlockKeyMaintenanceService

/// A service that keeps a user's biometric and never-lock unlock keys in sync with their current
/// user key after unlocking the vault, e.g. after a no-logout key rotation changes the user's key
/// without logging them out.
///
protocol UnlockKeyMaintenanceService: AnyObject { // sourcery: AutoMockable
    /// Restores the biometric unlock keychain entry after a vault unlock when the biometric
    /// preference is enabled but no keychain entry currently exists (e.g. because the preference
    /// survived a logout but the keychain entry was cleared).
    ///
    func configureBiometricUnlockIfNeeded() async

    /// Refreshes the stored biometric unlock key if it no longer matches the current user key,
    /// given a key and `LAContext` already obtained elsewhere (e.g. the read that just unlocked
    /// the vault via biometrics). Reusing them means this costs no additional Face/Touch ID prompt.
    ///
    /// - Parameters:
    ///   - storedKey: The current value of the stored biometric unlock key.
    ///   - context: The `LAContext` used to read `storedKey`, reused for the write if the key is stale.
    ///
    func refreshBiometricUnlockKeyIfStale(storedKey: String, context: LAContext) async

    /// Refreshes the stored never-lock key if one is stored and it no longer matches the current
    /// user key.
    ///
    func refreshNeverLockKeyIfStale() async
}

// MARK: - DefaultUnlockKeyMaintenanceService

/// A default implementation of an `UnlockKeyMaintenanceService`.
///
class DefaultUnlockKeyMaintenanceService: UnlockKeyMaintenanceService {
    // MARK: Properties

    /// The service to use system Biometrics for vault unlock.
    private let biometricsRepository: BiometricsRepository

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used by the application for recording temporary debug logs.
    private let flightRecorder: FlightRecorder

    /// The keychain service used by this service.
    private let keychainService: KeychainRepository

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultUnlockKeyMaintenanceService`.
    ///
    /// - Parameters:
    ///   - biometricsRepository: The service to use system Biometrics for vault unlock.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///   - keychainService: The keychain service used by this service.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        biometricsRepository: BiometricsRepository,
        clientService: ClientService,
        errorReporter: ErrorReporter,
        flightRecorder: FlightRecorder,
        keychainService: KeychainRepository,
        stateService: StateService,
    ) {
        self.biometricsRepository = biometricsRepository
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.flightRecorder = flightRecorder
        self.keychainService = keychainService
        self.stateService = stateService
    }

    // MARK: Methods

    func configureBiometricUnlockIfNeeded() async {
        do {
            guard try await biometricsRepository.getBiometricUnlockStatus().isEnabled else { return }
            guard await !biometricsRepository.hasBiometricUnlockKey() else { return }
            let authKey = try await clientService.crypto().getUserEncryptionKey()
            try await biometricsRepository.restoreBiometricUnlockKey(authKey: authKey)
        } catch BiometricsServiceError.biometryLocked {
            // Lockout is a transient state; do nothing and let the user retry later.
        } catch {
            errorReporter.log(error: error)
        }
    }

    func refreshBiometricUnlockKeyIfStale(storedKey: String, context: LAContext) async {
        do {
            guard try await biometricsRepository.getBiometricUnlockStatus().isEnabled else { return }
            guard let currentKey = try await currentUserKeyIfStale(comparedTo: storedKey) else { return }

            try await biometricsRepository.restoreBiometricUnlockKey(authKey: currentKey, userId: nil, context: context)
            await flightRecorder.log("[Auth] Refreshed stale biometric unlock key")
        } catch BiometricsServiceError.biometryLocked, BiometricsServiceError.biometryCancelled {
            // Transient states; do nothing and let the user retry later.
        } catch {
            errorReporter.log(error: error)
        }
    }

    func refreshNeverLockKeyIfStale() async {
        do {
            let userId = try await stateService.getActiveAccountId()
            let item = BitwardenKeychainItem.neverLock(userId: userId)
            let storedKey = try await keychainService.getUserAuthKeyValue(for: item)
            guard let currentKey = try await currentUserKeyIfStale(comparedTo: storedKey) else { return }

            try await keychainService.setUserAuthKey(for: item, value: currentKey)
            await flightRecorder.log("[Auth] Refreshed stale never-lock key")
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            // No never-lock key is currently stored; nothing to refresh.
        } catch {
            errorReporter.log(error: error)
        }
    }

    // MARK: Private

    /// Returns the user's current encryption key if its key ID differs from `storedKey`'s, or
    /// `nil` if `storedKey` already matches the current user key.
    ///
    /// - Parameter storedKey: The previously stored key to compare against the current user key.
    /// - Returns: The current user encryption key if it's different from `storedKey`, otherwise `nil`.
    ///
    private func currentUserKeyIfStale(comparedTo storedKey: String) async throws -> String? {
        let crypto = try await clientService.crypto()
        let currentKey = try await crypto.getUserEncryptionKey()
        guard try crypto.getKeyIdForSymmetricKey(key: storedKey) != crypto.getKeyIdForSymmetricKey(key: currentKey)
        else { return nil }
        return currentKey
    }
}
