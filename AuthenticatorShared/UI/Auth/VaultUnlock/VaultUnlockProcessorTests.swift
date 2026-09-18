import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import AuthenticatorShared

// MARK: - VaultUnlockProcessorTests

@MainActor
struct VaultUnlockProcessorTests {
    // MARK: Properties

    let biometricsRepository: MockBiometricsRepository
    let coordinator: MockCoordinator<AuthRoute, AuthEvent>
    let errorReporter: MockErrorReporter
    let subject: VaultUnlockProcessor

    // MARK: Initialization

    init() {
        biometricsRepository = MockBiometricsRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        subject = VaultUnlockProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                biometricsRepository: biometricsRepository,
                errorReporter: errorReporter,
            ),
            state: VaultUnlockState(),
        )
    }

    // MARK: Tests

    /// `perform(.appeared)` unlocks the vault when biometrics are enabled and the auth key is available.
    @Test
    func perform_appeared_biometricsEnabled_unlocksVault() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        biometricsRepository.getUserAuthKeyReturnValue = "auth key"

        await subject.perform(.appeared)

        #expect(coordinator.events == [.didCompleteAuth])
    }

    /// `perform(.appeared)` doesn't attempt an unlock when biometrics aren't available.
    @Test
    func perform_appeared_biometricsNotAvailable_doesNotAttemptUnlock() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .notAvailable

        await subject.perform(.appeared)

        #expect(subject.state.biometricUnlockStatus == .notAvailable)
        #expect(biometricsRepository.getUserAuthKeyCalled == false)
        #expect(coordinator.events.isEmpty)
    }

    /// `perform(.unlockWithBiometrics)` disables biometric unlock and lets the user into the app when
    /// biometrics are enabled but the auth key is missing from the keychain.
    ///
    /// The key is unrecoverable once it's gone — it's lost when the app is reinstalled or the device
    /// is restored from a backup, neither of which clears the user's stored preference. Leaving the
    /// preference enabled would strand the user on the unlock screen behind a button that can never
    /// succeed.
    @Test
    func perform_unlockWithBiometrics_getAuthKeyFailed_disablesBiometricsAndCompletesAuth() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        biometricsRepository.getUserAuthKeyThrowableError = BiometricsServiceError.getAuthKeyFailed

        await subject.perform(.unlockWithBiometrics)

        #expect(biometricsRepository.setBiometricUnlockKeyCalled)
        #expect(biometricsRepository.setBiometricUnlockKeyReceivedArguments?.authKey == nil)
        #expect(errorReporter.errors.count == 1)
        #expect(coordinator.events == [.didCompleteAuth])
    }

    /// `perform(.unlockWithBiometrics)` still lets the user into the app when clearing the stale
    /// biometric unlock preference fails.
    @Test
    func perform_unlockWithBiometrics_getAuthKeyFailed_completesAuthWhenDisablingThrows() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        biometricsRepository.getUserAuthKeyThrowableError = BiometricsServiceError.getAuthKeyFailed
        biometricsRepository.setBiometricUnlockKeyThrowableError = BiometricsServiceError.setAuthKeyFailed

        await subject.perform(.unlockWithBiometrics)

        #expect(coordinator.events == [.didCompleteAuth])
    }

    /// `perform(.unlockWithBiometrics)` leaves the vault locked when the user cancels the prompt.
    @Test
    func perform_unlockWithBiometrics_cancelled_remainsLocked() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        biometricsRepository.getUserAuthKeyThrowableError = BiometricsServiceError.biometryCancelled

        await subject.perform(.unlockWithBiometrics)

        #expect(biometricsRepository.setBiometricUnlockKeyCalled == false)
        #expect(coordinator.events.isEmpty)
    }

    /// `perform(.unlockWithBiometrics)` leaves biometric unlock enabled for errors that a retry can
    /// recover from.
    @Test
    func perform_unlockWithBiometrics_recoverableError_remainsLocked() async {
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        biometricsRepository.getUserAuthKeyThrowableError = BiometricsServiceError.biometryFailed

        await subject.perform(.unlockWithBiometrics)

        #expect(biometricsRepository.setBiometricUnlockKeyCalled == false)
        #expect(coordinator.events.isEmpty)
        #expect(subject.state.biometricUnlockStatus == .available(.faceID, enabled: true))
    }
}
