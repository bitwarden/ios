import BitwardenResources

// MARK: - VaultUnlockSetupProcessor

/// The processor used to manage state and handle actions for the vault unlock setup screen.
///
class VaultUnlockSetupProcessor: StateProcessor<VaultUnlockSetupState, VaultUnlockSetupAction, VaultUnlockSetupEffect> {
    // MARK: Types

    typealias Services = DefaultVaultUnlockSetupHelper.Services

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by this processor.
    private let services: Services

    /// A helper object to set up vault unlock methods.
    private let vaultUnlockSetupHelper: VaultUnlockSetupHelper

    // MARK: Initialization

    /// Creates a new `VaultUnlockSetupProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///   - vaultUnlockSetupHelper: A helper object to set up vault unlock methods.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: VaultUnlockSetupState,
        vaultUnlockSetupHelper: VaultUnlockSetupHelper
    ) {
        self.coordinator = coordinator
        self.services = services
        self.vaultUnlockSetupHelper = vaultUnlockSetupHelper
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultUnlockSetupEffect) async {
        switch effect {
        case .continueFlow:
            await continueFlow()
        case .loadData:
            await loadData()
        case let .toggleUnlockMethod(unlockMethod, newValue):
            switch unlockMethod {
            case .biometrics:
                await toggleBiometricUnlock(enabled: newValue)
            case .pin:
                await togglePinUnlock(enabled: newValue)
            }
        }
    }

    override func receive(_ action: VaultUnlockSetupAction) {
        switch action {
        case .setUpLater:
            showSetUpLaterAlert()
        }
    }

    // MARK: Private

    /// Continues the set up unlock flow by navigating to autofill setup.
    ///
    private func continueFlow() async {
        do {
            try await services.stateService.setAccountSetupVaultUnlock(.complete)
        } catch {
            services.errorReporter.log(error: error)
        }

        switch state.accountSetupFlow {
        case .createAccount:
            await coordinator.handleEvent(.didCompleteAuth)
        case .settings:
            coordinator.navigate(to: .dismiss)
        }
    }

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

    /// Shows the alert confirming that the user wants to proceed without setting up their unlock
    /// methods.
    ///
    private func showSetUpLaterAlert() {
        coordinator.showAlert(.setUpUnlockMethodLater {
            do {
                try await self.services.stateService.setAccountSetupVaultUnlock(.setUpLater)
            } catch {
                self.services.errorReporter.log(error: error)
            }
            await self.coordinator.handleEvent(.didCompleteAuth)
        })
    }

    /// Toggles whether unlock with biometrics is enabled.
    ///
    /// - Parameter enabled: Whether to enable unlock with biometrics.
    ///
    private func toggleBiometricUnlock(enabled: Bool) async {
        state.biometricsStatus = await vaultUnlockSetupHelper.setBiometricUnlock(
            enabled: enabled,
            showAlert: coordinator.showAlert
        )
    }

    /// Toggles whether unlock with pin is enabled.
    ///
    /// - Parameter enabled: Whether to enable unlock with biometrics.
    ///
    private func togglePinUnlock(enabled: Bool) async {
        state.isPinUnlockOn = await vaultUnlockSetupHelper.setPinUnlock(
            enabled: enabled,
            showAlert: coordinator.showAlert
        )
    }
}
