// MARK: - VaultUnlockSetupProcessor

/// The processor used to manage state and handle actions for the vault unlock setup screen.
///
class VaultUnlockSetupProcessor: StateProcessor<VaultUnlockSetupState, VaultUnlockSetupAction, VaultUnlockSetupEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasBiometricsRepository
        & HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `VaultUnlockSetupProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: VaultUnlockSetupState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultUnlockSetupEffect) async {
        switch effect {
        case .loadData:
            await loadData()
        }
    }

    override func receive(_ action: VaultUnlockSetupAction) {
        switch action {
        case .continueFlow:
            // TODO: PM-10278 Navigate to autofill setup
            break
        case .setUpLater:
            // TODO: PM-10270 Skip unlock setup
            break
        case let .toggleUnlockMethod(unlockMethod, newValue):
            switch unlockMethod {
            case .biometrics:
                Task {
                    await toggleBiometricUnlock(enabled: newValue)
                }
            case .pin:
                state.isPinUnlockOn = newValue
            }
        }
    }

    // MARK: Private

    /// Load any initial data for the view.
    ///
    private func loadData() async {
        do {
            state.biometricsStatus = try await services.biometricsRepository.getBiometricUnlockStatus()
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Toggles whether unlock with biometrics is enabled.
    ///
    /// - Parameter enabled: Whether to enable unlock with biometrics.
    ///
    private func toggleBiometricUnlock(enabled: Bool) async {
        do {
            try await services.authRepository.allowBioMetricUnlock(enabled)
            state.biometricsStatus = try await services.biometricsRepository.getBiometricUnlockStatus()
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }
}
