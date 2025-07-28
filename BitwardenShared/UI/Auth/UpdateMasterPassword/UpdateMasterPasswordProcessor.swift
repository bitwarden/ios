import BitwardenKit
import BitwardenResources
@preconcurrency import BitwardenSdk
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
        & HasConfigService
        & HasErrorReporter
        & HasPolicyService
        & HasSettingsRepository
        & HasStateService

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
        case .logoutTapped:
            showLogoutConfirmation()
        case .saveTapped:
            await updateMasterPassword()
        }
    }

    override func receive(_ action: UpdateMasterPasswordAction) {
        switch action {
        case let .currentMasterPasswordChanged(newValue):
            state.currentMasterPassword = newValue
        case let .masterPasswordChanged(newValue):
            state.masterPassword = newValue
            updatePasswordStrength()
        case let .masterPasswordHintChanged(newValue):
            state.masterPasswordHint = newValue
        case let .masterPasswordRetypeChanged(newValue):
            state.masterPasswordRetype = newValue
        case .preventAccountLockTapped:
            coordinator.navigate(to: .preventAccountLock)
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
            coordinator.navigate(to: .dismiss)
        }
        coordinator.showAlert(alert)
    }

    /// Syncs the user's vault with the API.
    ///
    private func syncVault() async {
        coordinator.showLoadingOverlay(title: Localizations.syncing)
        defer { coordinator.hideLoadingOverlay() }

        do {
            try await services.settingsRepository.fetchSync()
            let account = try await services.authRepository.getAccount()
            state.userEmail = account.profile.email
            state.forcePasswordResetReason = account.profile.forcePasswordResetReason

            if let policy = try await services.policyService.getMasterPasswordPolicyOptions() {
                state.masterPasswordPolicy = policy
            } else if state.forcePasswordResetReason == .weakMasterPasswordOnLogin {
                // If the reset reason is because of a weak password, but there's no policy don't
                // require a master password update.
                coordinator.hideLoadingOverlay()
                try await services.stateService.setForcePasswordResetReason(nil)
                await coordinator.handleEvent(.didCompleteAuth)
            }
        } catch {
            await coordinator.showErrorAlert(error: error) {
                await self.syncVault()
            }
            services.errorReporter.log(error: error)
        }
    }

    /// Updates the master password.
    ///
    private func updateMasterPassword() async {
        guard let forcePasswordResetReason = state.forcePasswordResetReason else {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            return
        }

        do {
            try EmptyInputValidator(fieldName: Localizations.masterPassword)
                .validate(input: state.masterPassword)

            if state.masterPasswordPolicy?.isInEffect == true {
                let isInvalid = try await services.authService.requirePasswordChange(
                    email: services.authRepository.getAccount().profile.email,
                    isPreAuth: false,
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
                reason: forcePasswordResetReason
            )

            coordinator.hideLoadingOverlay()
            coordinator.navigate(to: .dismiss)
            await coordinator.handleEvent(.didCompleteAuth)
        } catch let error as InputValidationError {
            coordinator.showAlert(.inputValidationAlert(error: error))
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Updates state's password strength score based on the user's entered password.
    ///
    private func updatePasswordStrength() {
        guard !state.masterPassword.isEmpty else {
            state.passwordStrengthScore = nil
            return
        }
        Task {
            do {
                state.passwordStrengthScore = try await services.authRepository.passwordStrength(
                    email: state.userEmail,
                    password: state.masterPassword,
                    isPreAuth: false
                )
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }
}
