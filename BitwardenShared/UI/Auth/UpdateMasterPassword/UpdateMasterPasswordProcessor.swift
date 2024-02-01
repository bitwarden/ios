import BitwardenSdk
import Foundation

// MARK: - UpdateMasterPasswordProcessor

/// The processor used to manage state and handle actions for the update master password screen.
///
class UpdateMasterPasswordProcessor: StateProcessor<
    UpdateMasterPasswordState,
    UpdateMasterPasswordAction,
    UpdateMasterPasswordEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasAuthService
        & HasErrorReporter
        & HasPolicyService
        & HasSettingsRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute, Void>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `UpdateMasterPasswordProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, Void>,
        services: Services,
        state: UpdateMasterPasswordState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: UpdateMasterPasswordEffect) async {
        switch effect {
        case .appeared:
            await syncVault()
        case .logoutPressed:
            // TODO: BIT-789
            break
        case .submitPressed:
            await updateMasterPassword()
        }
    }

    override func receive(_ action: UpdateMasterPasswordAction) {
        switch action {
        case let .currentMasterPasswordChanged(newValue):
            state.currentMasterPassword = newValue
        case let .masterPasswordChanged(newValue):
            state.masterPassword = newValue
        case let .masterPasswordHintChanged(newValue):
            state.masterPasswordHint = newValue
        case let .masterPasswordRetypeChanged(newValue):
            state.masterPasswordRetype = newValue
        case let .revealCurrentMasterPasswordFieldPressed(isOn):
            state.isCurrentMasterPasswordRevealed = isOn
        case let .revealMasterPasswordFieldPressed(isOn):
            state.isMasterPasswordRevealed = isOn
        case let .revealMasterPasswordRetypeFieldPressed(isOn):
            state.isMasterPasswordRetypeRevealed = isOn
        }
    }

    // MARK: Private Methods

    /// Updates the master password
    ///
    private func updateMasterPassword() async {
        // TODO: BIT-789
    }

    /// Syncs the user's vault with the API.
    ///
    private func syncVault() async {
        coordinator.showLoadingOverlay(title: Localizations.syncing)
        defer { coordinator.hideLoadingOverlay() }

        do {
            try await services.settingsRepository.fetchSync()
            if let policy = try await services.policyService.getMasterPasswordPolicyOptions() {
                state.masterPasswordPolicy = policy
            } else {
                coordinator.navigate(to: .complete)
            }
            coordinator.hideLoadingOverlay()
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.syncVault()
            })
            services.errorReporter.log(error: error)
        }
    }
}
