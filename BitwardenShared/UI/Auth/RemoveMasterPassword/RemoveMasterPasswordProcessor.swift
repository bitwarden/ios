import BitwardenResources
import BitwardenSdk

// MARK: - RemoveMasterPasswordProcessor

/// The processor used to manage state and handle actions for the remove master password screen.
///
class RemoveMasterPasswordProcessor: StateProcessor<
    RemoveMasterPasswordState,
    RemoveMasterPasswordAction,
    RemoveMasterPasswordEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasConfigService
        & HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `RemoveMasterPasswordProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: RemoveMasterPasswordState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: RemoveMasterPasswordEffect) async {
        switch effect {
        case .continueFlow:
            await migrateUser()
        case .leaveOrganizationFlow:
            showLeaveOrganizationConfirmation()
        }
    }

    override func receive(_ action: RemoveMasterPasswordAction) {
        switch action {
        case let .masterPasswordChanged(masterPassword):
            state.masterPassword = masterPassword
        case let .revealMasterPasswordFieldPressed(isMasterPasswordRevealed):
            state.isMasterPasswordRevealed = isMasterPasswordRevealed
        }
    }

    // MARK: Private

    /// User leaves the current key connector organization
    ///
    private func leaveOrganization() async {
        do {
            coordinator.showLoadingOverlay(title: Localizations.loading)
            defer { coordinator.hideLoadingOverlay() }

            try await services.authRepository.leaveOrganization(organizationId: state.organizationId)
            let userId = try await services.authRepository.getUserId()
            try await services.authRepository.logout(userId: userId, userInitiated: true)

            await coordinator.handleEvent(.didLogout(userId: userId, userInitiated: true))
            coordinator.hideLoadingOverlay()
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }

    /// Migrates the user to use Key Connector.
    ///
    private func migrateUser() async {
        do {
            coordinator.showLoadingOverlay(title: Localizations.loading)
            defer { coordinator.hideLoadingOverlay() }

            try EmptyInputValidator(fieldName: Localizations.masterPassword)
                .validate(input: state.masterPassword)

            try await services.authRepository.migrateUserToKeyConnector(password: state.masterPassword)

            coordinator.hideLoadingOverlay()
            await coordinator.handleEvent(.didCompleteAuth)
        } catch let error as InputValidationError {
            coordinator.showAlert(Alert.inputValidationAlert(error: error))
        } catch is BitwardenSdk.BitwardenError {
            coordinator.showAlert(.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.invalidMasterPassword
            ))
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }

    /// Shows an alert asking the user to confirm that they want to logout.
    ///
    private func showLeaveOrganizationConfirmation() {
        let alert = Alert.leaveOrganizationConfirmation(orgName: state.organizationName) { [weak self] in
            guard let self else { return }
            await leaveOrganization()
        }
        coordinator.showAlert(alert)
    }
}
