import BitwardenResources

// MARK: - PasswordHintProcessor

/// The processor used to manage state and handle actions for the passwort hint screen.
///
class PasswordHintProcessor: StateProcessor<PasswordHintState, PasswordHintAction, PasswordHintEffect> {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasConfigService
        & HasErrorReporter

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `PasswordHintProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: PasswordHintState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: PasswordHintEffect) async {
        switch effect {
        case .submitPressed:
            await requestPasswordHint(for: state.emailAddress)
        }
    }

    override func receive(_ action: PasswordHintAction) {
        switch action {
        case .dismissPressed:
            coordinator.navigate(to: .dismiss)
        case let .emailAddressChanged(newValue):
            state.emailAddress = newValue
        }
    }

    // MARK: Private Methods

    /// Requests the master password hint for the provided email address.
    ///
    /// - Parameter emailAddress: The email address to request the master password hint for.
    ///
    private func requestPasswordHint(for emailAddress: String) async {
        defer { coordinator.hideLoadingOverlay() }
        coordinator.showLoadingOverlay(title: Localizations.submitting)

        do {
            try await services.accountAPIService.requestPasswordHint(for: emailAddress)

            let okAction = AlertAction(title: Localizations.ok, style: .default) { _, _ in
                self.coordinator.navigate(to: .dismiss)
            }
            let alert = Alert(
                title: "",
                message: Localizations.passwordHintAlert,
                alertActions: [okAction]
            )

            coordinator.hideLoadingOverlay()
            coordinator.showAlert(alert)
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }
}
