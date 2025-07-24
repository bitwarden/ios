import BitwardenKit
import BitwardenResources
@preconcurrency import BitwardenSdk
import Foundation

// MARK: - SetMasterPasswordProcessor

/// The processor used to manage state and handle actions for the set master password screen.
///
class SetMasterPasswordProcessor: StateProcessor<
    SetMasterPasswordState,
    SetMasterPasswordAction,
    SetMasterPasswordEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasAuthService
        & HasConfigService
        & HasErrorReporter
        & HasOrganizationAPIService
        & HasPolicyService
        & HasSettingsRepository
        & HasStateService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `SetMasterPasswordProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: SetMasterPasswordState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SetMasterPasswordEffect) async {
        switch effect {
        case .appeared:
            await loadData()
        case .cancelPressed:
            coordinator.navigate(to: .dismiss)
        case .saveTapped:
            await setPassword()
        }
    }

    override func receive(_ action: SetMasterPasswordAction) {
        switch action {
        case let .masterPasswordChanged(newValue):
            state.masterPassword = newValue
        case let .masterPasswordHintChanged(newValue):
            state.masterPasswordHint = newValue
        case let .masterPasswordRetypeChanged(newValue):
            state.masterPasswordRetype = newValue
        case .preventAccountLockTapped:
            coordinator.navigate(to: .preventAccountLock)
        case let .revealMasterPasswordFieldPressed(isOn):
            state.isMasterPasswordRevealed = isOn
        }
    }

    // MARK: Private Methods

    /// Loads any data needed to render the view.
    ///
    private func loadData() async {
        coordinator.showLoadingOverlay(title: Localizations.syncing)
        defer { coordinator.hideLoadingOverlay() }

        do {
            let account = try await services.authRepository.getAccount()
            state.isPrivilegeElevation = account.profile.userDecryptionOptions?.trustedDeviceOption != nil

            let response = try await services.organizationAPIService.getOrganizationAutoEnrollStatus(
                identifier: state.organizationIdentifier
            )
            state.organizationId = response.id
            state.resetPasswordAutoEnroll = response.resetPasswordEnabled

            if !state.isPrivilegeElevation {
                try await services.settingsRepository.fetchSync()
            }

            if let policy = try await services.policyService.getMasterPasswordPolicyOptions() {
                state.masterPasswordPolicy = policy
            }
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Sets the user's password.
    ///
    private func setPassword() async {
        guard let organizationId = state.organizationId else {
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

            coordinator.showLoadingOverlay(title: Localizations.loading)
            defer { coordinator.hideLoadingOverlay() }

            try await services.authRepository.setMasterPassword(
                state.masterPassword,
                masterPasswordHint: state.masterPasswordHint,
                organizationId: organizationId,
                organizationIdentifier: state.organizationIdentifier,
                resetPasswordAutoEnroll: state.resetPasswordAutoEnroll
            )

            await coordinator.handleEvent(.didCompleteAuth)
        } catch let error as InputValidationError {
            coordinator.showAlert(.inputValidationAlert(error: error))
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }
}
