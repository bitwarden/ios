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
    private var coordinator: AnyCoordinator<AuthRoute, AuthEvent>

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
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
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
            showLogoutConfirmation()
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

    /// Shows an alert asking the user to confirm that they want to logout.
    ///
    private func showLogoutConfirmation() {
        let alert = Alert.logoutConfirmation { [weak self] in
            guard let self else { return }
            await coordinator.handleEvent(.action(.logout(userId: nil, userInitiated: true)))
        }
        coordinator.navigate(to: .alert(alert))
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
                coordinator.hideLoadingOverlay()
                coordinator.navigate(to: .complete)
            }
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.syncVault()
            })
            services.errorReporter.log(error: error)
        }
    }

    /// Updates the master password.
    ///
    private func updateMasterPassword() async {
        do {
            try EmptyInputValidator(fieldName: Localizations.masterPassword)
                .validate(input: state.masterPassword)

            if state.masterPasswordPolicy?.inEffect() == true {
                let isInvalid = try await services.authService.requirePasswordChange(
                    email: services.authRepository.getAccount().profile.email,
                    masterPassword: state.masterPassword,
                    policy: state.masterPasswordPolicy
                )
                guard !isInvalid else {
                    coordinator.showAlert(.masterPasswordInvalid())
                    return
                }
            }

            guard state.masterPassword.count >= Constants.minimumPasswordCharacters else {
                coordinator.showAlert(.passwordIsTooShort)
                return
            }

            guard state.masterPassword == state.masterPasswordRetype else {
                coordinator.showAlert(.passwordsDontMatch)
                return
            }

            coordinator.showLoadingOverlay(title: Localizations.updatingPassword)
            defer { coordinator.hideLoadingOverlay() }

            try await services.authRepository.updateMasterPassword(
                currentPassword: state.currentMasterPassword,
                newPassword: state.masterPassword,
                passwordHint: state.masterPasswordHint,
                reason: .weakMasterPasswordOnLogin
            )

            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .dismiss)
            coordinator.navigate(to: .complete)
        } catch let error as InputValidationError {
            coordinator.showAlert(.inputValidationAlert(error: error))
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }
}
