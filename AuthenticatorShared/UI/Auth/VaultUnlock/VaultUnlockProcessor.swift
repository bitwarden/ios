import BitwardenKit
import OSLog

// MARK: - VaultUnlockProcessor

/// The processor used to manage state and handle actions for the unlock screen.
///
class VaultUnlockProcessor: StateProcessor<
    VaultUnlockState,
    VaultUnlockAction,
    VaultUnlockEffect,
> {
    // MARK: Types

    typealias Services = HasBiometricsRepository
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// A flag indicating if the processor should attempt automatic biometric unlock
    var shouldAttemptAutomaticBiometricUnlock = true

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `VaultUnlockProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: VaultUnlockState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultUnlockEffect) async {
        switch effect {
        case .appeared:
            await loadData()
        case .unlockWithBiometrics:
            await unlockWithBiometrics()
        }
    }

    override func receive(_ action: VaultUnlockAction) {
        switch action {
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private Methods

    /// Loads the async state data for the view
    ///
    private func loadData() async {
        state.biometricUnlockStatus = await (try? services.biometricsRepository.getBiometricUnlockStatus())
            ?? .notAvailable
        // If biometric unlock is available and enabled
        // attempt to unlock the vault with biometrics once.
        if case .available(_, enabled: true) = state.biometricUnlockStatus,
           shouldAttemptAutomaticBiometricUnlock {
            shouldAttemptAutomaticBiometricUnlock = false
            await unlockWithBiometrics()
        }
    }

    /// Attempts to unlock the vault with the user's biometrics
    ///
    private func unlockWithBiometrics() async {
        let status = try? await services.biometricsRepository.getBiometricUnlockStatus()
        guard case let .available(_, enabled: enabled) = status,
              enabled else {
            await loadData()
            return
        }

        do {
            _ = try await services.biometricsRepository.getUserAuthKey()
            await coordinator.handleEvent(.didCompleteAuth)
        } catch BiometricsServiceError.biometryCancelled {
            // Do nothing if the user cancels.
            Logger.processor.error("Biometric unlock cancelled.")
        } catch BiometricsServiceError.getAuthKeyFailed {
            // Biometric unlock is enabled, but the key is missing from the keychain. This happens
            // when the app is reinstalled or the device is restored from a backup, either of which
            // preserves the user's preference but not the biometric key.
            //
            // The key can never be recovered, so leaving the preference enabled strands the user on
            // the unlock screen behind a button that cannot succeed. Clear the stale preference so
            // the app returns to its unlocked state, matching what the user gets today by manually
            // revoking the app's biometrics permission in the Settings app.
            services.errorReporter.log(error: BitwardenError.generalError(
                type: "VaultUnlock: Get Biometrics Auth Key Failed",
                message: "Biometrics auth is enabled but key was unable to be found. Disabling biometric unlock.",
            ))
            try? await services.biometricsRepository.setBiometricUnlockKey(authKey: nil)
            await coordinator.handleEvent(.didCompleteAuth)
        } catch {
            Logger.processor.error("Error unlocking vault with biometrics: \(error)")
            await loadData()
        }
    }
}
