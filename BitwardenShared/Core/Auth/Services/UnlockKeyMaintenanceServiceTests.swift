import BitwardenKit
import BitwardenKitMocks
import LocalAuthentication
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - UnlockKeyMaintenanceServiceTests

@MainActor
struct UnlockKeyMaintenanceServiceTests {
    // MARK: Properties

    let biometricsRepository: MockBiometricsRepository
    let clientService: MockClientService
    let errorReporter: MockErrorReporter
    let flightRecorder: MockFlightRecorder
    let keychainService: MockKeychainRepository
    let stateService: MockStateService
    let subject: DefaultUnlockKeyMaintenanceService

    // MARK: Initialization

    init() {
        biometricsRepository = MockBiometricsRepository()
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        flightRecorder = MockFlightRecorder()
        keychainService = MockKeychainRepository()
        stateService = MockStateService()

        stateService.activeAccount = .fixture()
        biometricsRepository.getBiometricUnlockStatusReturnValue = .notAvailable

        subject = DefaultUnlockKeyMaintenanceService(
            biometricsRepository: biometricsRepository,
            clientService: clientService,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            keychainService: keychainService,
            stateService: stateService,
        )
    }

    // MARK: Tests - configureBiometricUnlockIfNeeded()

    /// `configureBiometricUnlockIfNeeded()` swallows a transient biometry-locked error.
    @Test
    func configureBiometricUnlockIfNeeded_biometryLocked() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        biometricsRepository.hasBiometricUnlockKeyReturnValue = false
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "ENC_KEY"
        biometricsRepository.restoreBiometricUnlockKeyThrowableError = BiometricsServiceError.biometryLocked

        await subject.configureBiometricUnlockIfNeeded()

        #expect(errorReporter.errors.isEmpty)
    }

    /// `configureBiometricUnlockIfNeeded()` does nothing when biometrics isn't enabled.
    @Test
    func configureBiometricUnlockIfNeeded_doesNothingWhenDisabled() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .notAvailable

        await subject.configureBiometricUnlockIfNeeded()

        #expect(!biometricsRepository.restoreBiometricUnlockKeyCalled)
    }

    /// `configureBiometricUnlockIfNeeded()` does nothing when a biometric key already exists.
    @Test
    func configureBiometricUnlockIfNeeded_doesNothingWhenKeyExists() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        biometricsRepository.hasBiometricUnlockKeyReturnValue = true

        await subject.configureBiometricUnlockIfNeeded()

        #expect(!biometricsRepository.restoreBiometricUnlockKeyCalled)
        #expect(!clientService.mockCrypto.getUserEncryptionKeyCalled)
    }

    /// `configureBiometricUnlockIfNeeded()` logs an unexpected error, rather than silently
    /// swallowing it.
    @Test
    func configureBiometricUnlockIfNeeded_logsUnexpectedError() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        biometricsRepository.hasBiometricUnlockKeyReturnValue = false
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "ENC_KEY"
        biometricsRepository.restoreBiometricUnlockKeyThrowableError = BitwardenTestError.example

        await subject.configureBiometricUnlockIfNeeded()

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `configureBiometricUnlockIfNeeded()` restores the biometric key when biometrics is enabled
    /// but no key is currently stored.
    @Test
    func configureBiometricUnlockIfNeeded_restoresWhenMissing() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        biometricsRepository.hasBiometricUnlockKeyReturnValue = false
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "ENC_KEY"

        await subject.configureBiometricUnlockIfNeeded()

        #expect(biometricsRepository.restoreBiometricUnlockKeyCalled)
        #expect(biometricsRepository.restoreBiometricUnlockKeyReceivedArguments?.authKey == "ENC_KEY")
    }

    // MARK: Tests - refreshBiometricUnlockKeyIfStale(storedKey:context:)

    /// `refreshBiometricUnlockKeyIfStale(storedKey:context:)` swallows a transient biometry-cancelled error.
    @Test
    func refreshBiometricUnlockKeyWithContext_biometryCancelled() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "NEW_ENC_KEY"
        clientService.mockCrypto.getKeyIdForSymmetricKeyClosure = { key in
            key == "OLD_ENC_KEY" ? "OLD_KEY_ID" : "NEW_KEY_ID"
        }
        biometricsRepository.restoreBiometricUnlockKeyThrowableError = BiometricsServiceError.biometryCancelled

        await subject.refreshBiometricUnlockKeyIfStale(storedKey: "OLD_ENC_KEY", context: LAContext())

        #expect(errorReporter.errors.isEmpty)
        #expect(flightRecorder.logMessages.isEmpty)
    }

    /// `refreshBiometricUnlockKeyIfStale(storedKey:context:)` swallows a transient biometry-locked error.
    @Test
    func refreshBiometricUnlockKeyWithContext_biometryLocked() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "NEW_ENC_KEY"
        clientService.mockCrypto.getKeyIdForSymmetricKeyClosure = { key in
            key == "OLD_ENC_KEY" ? "OLD_KEY_ID" : "NEW_KEY_ID"
        }
        biometricsRepository.restoreBiometricUnlockKeyThrowableError = BiometricsServiceError.biometryLocked

        await subject.refreshBiometricUnlockKeyIfStale(storedKey: "OLD_ENC_KEY", context: LAContext())

        #expect(errorReporter.errors.isEmpty)
        #expect(flightRecorder.logMessages.isEmpty)
    }

    /// `refreshBiometricUnlockKeyIfStale(storedKey:context:)` does nothing when the given key's ID
    /// still matches the current user key.
    @Test
    func refreshBiometricUnlockKeyWithContext_doesNothingWhenCurrent() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "STORED_ENC_KEY"
        clientService.mockCrypto.getKeyIdForSymmetricKeyReturnValue = "SAME_KEY_ID"

        await subject.refreshBiometricUnlockKeyIfStale(storedKey: "STORED_ENC_KEY", context: LAContext())

        #expect(!biometricsRepository.restoreBiometricUnlockKeyCalled)
    }

    /// `refreshBiometricUnlockKeyIfStale(storedKey:context:)` does nothing when biometrics isn't enabled,
    /// e.g. if it was disabled between the unlock read and this check.
    @Test
    func refreshBiometricUnlockKeyWithContext_doesNothingWhenDisabled() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .notAvailable

        await subject.refreshBiometricUnlockKeyIfStale(storedKey: "OLD_ENC_KEY", context: LAContext())

        #expect(!clientService.mockCrypto.getUserEncryptionKeyCalled)
        #expect(!biometricsRepository.restoreBiometricUnlockKeyCalled)
    }

    /// `refreshBiometricUnlockKeyIfStale(storedKey:context:)` logs an unexpected error, rather
    /// than silently swallowing it.
    @Test
    func refreshBiometricUnlockKeyWithContext_logsUnexpectedError() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "NEW_ENC_KEY"
        clientService.mockCrypto.getKeyIdForSymmetricKeyClosure = { key in
            key == "OLD_ENC_KEY" ? "OLD_KEY_ID" : "NEW_KEY_ID"
        }
        biometricsRepository.restoreBiometricUnlockKeyThrowableError = BitwardenTestError.example

        await subject.refreshBiometricUnlockKeyIfStale(storedKey: "OLD_ENC_KEY", context: LAContext())

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(flightRecorder.logMessages.isEmpty)
    }

    /// `refreshBiometricUnlockKeyIfStale(storedKey:context:)` refreshes the key when its ID no longer
    /// matches the current user key, reusing the given `LAContext` for the write.
    @Test
    func refreshBiometricUnlockKeyWithContext_refreshesWhenStale() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "NEW_ENC_KEY"
        clientService.mockCrypto.getKeyIdForSymmetricKeyClosure = { key in
            key == "OLD_ENC_KEY" ? "OLD_KEY_ID" : "NEW_KEY_ID"
        }
        let context = LAContext()

        await subject.refreshBiometricUnlockKeyIfStale(storedKey: "OLD_ENC_KEY", context: context)

        #expect(biometricsRepository.restoreBiometricUnlockKeyCalled)
        #expect(biometricsRepository.restoreBiometricUnlockKeyReceivedArguments?.authKey == "NEW_ENC_KEY")
        #expect(biometricsRepository.restoreBiometricUnlockKeyReceivedArguments?.context === context)
        #expect(flightRecorder.logMessages == ["[Auth] Refreshed stale biometric unlock key"])
    }

    // MARK: Tests - refreshNeverLockKeyIfStale()

    /// `refreshNeverLockKeyIfStale()` does nothing when the never-lock key's ID still matches the
    /// current user key.
    @Test
    func refreshNeverLockKeyIfStale_doesNothingWhenCurrent() async throws {
        keychainService.getUserAuthKeyValueReturnValue = "STORED_ENC_KEY"
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "ENC_KEY"
        clientService.mockCrypto.getKeyIdForSymmetricKeyReturnValue = "SAME_KEY_ID"

        await subject.refreshNeverLockKeyIfStale()

        #expect(keychainService.setUserAuthKeyReceivedArguments == nil)
        #expect(flightRecorder.logMessages.isEmpty)
    }

    /// `refreshNeverLockKeyIfStale()` does nothing, and doesn't log an error, when no never-lock
    /// key is currently stored.
    @Test
    func refreshNeverLockKeyIfStale_doesNothingWhenNoStoredKey() async throws {
        let userId = try #require(stateService.activeAccount).profile.userId
        keychainService.getUserAuthKeyValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.neverLock(userId: userId),
        )

        await subject.refreshNeverLockKeyIfStale()

        #expect(!clientService.mockCrypto.getUserEncryptionKeyCalled)
        #expect(keychainService.setUserAuthKeyReceivedArguments == nil)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `refreshNeverLockKeyIfStale()` logs an unexpected error reading the never-lock key, rather
    /// than silently swallowing it.
    @Test
    func refreshNeverLockKeyIfStale_logsUnexpectedError() async throws {
        keychainService.getUserAuthKeyValueThrowableError = BitwardenTestError.example

        await subject.refreshNeverLockKeyIfStale()

        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(keychainService.setUserAuthKeyReceivedArguments == nil)
    }

    /// `refreshNeverLockKeyIfStale()` refreshes the never-lock key when its ID no longer matches
    /// the current user key, e.g. after a no-logout key rotation.
    @Test
    func refreshNeverLockKeyIfStale_refreshesWhenStale() async throws {
        let userId = try #require(stateService.activeAccount).profile.userId
        keychainService.getUserAuthKeyValueReturnValue = "OLD_ENC_KEY"
        clientService.mockCrypto.getUserEncryptionKeyReturnValue = "NEW_ENC_KEY"
        clientService.mockCrypto.getKeyIdForSymmetricKeyClosure = { key in
            key == "OLD_ENC_KEY" ? "OLD_KEY_ID" : "NEW_KEY_ID"
        }

        await subject.refreshNeverLockKeyIfStale()

        #expect(keychainService.setUserAuthKeyReceivedArguments?.item == .neverLock(userId: userId))
        #expect(keychainService.setUserAuthKeyReceivedArguments?.value == "NEW_ENC_KEY")
        #expect(flightRecorder.logMessages == ["[Auth] Refreshed stale never-lock key"])
    }
}
