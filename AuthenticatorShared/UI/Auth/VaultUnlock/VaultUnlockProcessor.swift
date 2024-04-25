import OSLog

// MARK: - VaultUnlockProcessor

/// The processor used to manage state and handle actions for the unlock screen.
///
class VaultUnlockProcessor: StateProcessor<
    VaultUnlockState,
    VaultUnlockAction,
    VaultUnlockEffect
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
        state: VaultUnlockState
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
        // If biometric unlock is available, enabled,
        // and the user's biometric integrity state is valid;
        // attempt to unlock the vault with biometrics once.
        if case .available(_, true, true) = state.biometricUnlockStatus,
           shouldAttemptAutomaticBiometricUnlock {
            shouldAttemptAutomaticBiometricUnlock = false
            await unlockWithBiometrics()
        }
    }

    /// Attempts to unlock the vault with the user's biometrics
    ///
    private func unlockWithBiometrics() async {
        let status = try? await services.biometricsRepository.getBiometricUnlockStatus()
        guard case let .available(_, enabled: enabled, hasValidIntegrity) = status,
              enabled,
              hasValidIntegrity else {
            await loadData()
            return
        }

        do {
            let key = try await services.biometricsRepository.getUserAuthKey()
            await coordinator.handleEvent(.didCompleteAuth)
        } catch let error as BiometricsServiceError {
            Logger.processor.error("BiometricsServiceError unlocking vault with biometrics: \(error)")
            if case .biometryCancelled = error {
                // Do nothing if the user cancels.
                return
            }
            await loadData()
        } catch {
            Logger.processor.error("Error unlocking vault with biometrics: \(error)")
            await loadData()
        }
    }
}
