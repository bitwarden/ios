import Combine

// MARK: - LandingProcessor

/// The processor used to manage state and handle actions for the landing screen.
///
class LandingProcessor: StateProcessor<LandingState, LandingAction, Void> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    // MARK: Initialization

    /// Creates a new `LandingProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(coordinator: AnyCoordinator<AuthRoute>, state: LandingState) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: LandingAction) {
        switch action {
        case .continuePressed:
            validateEmailAndContinue()
        case .createAccountPressed:
            coordinator.navigate(to: .createAccount)
        case let .emailChanged(newValue):
            state.email = newValue
        case .regionPressed:
            presentRegionSelectionAlert()
        case let .rememberMeChanged(newValue):
            state.isRememberMeOn = newValue
        }
    }

    // MARK: Private Methods

    /// Validate the currently entered email address and navigate to the login screen.
    ///
    private func validateEmailAndContinue() {
        let email = state.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.isValidEmail else {
            coordinator.navigate(to: .alert(.invalidEmail))
            return
        }

        // Region placeholder until region selection support is added: BIT-268
        coordinator.navigate(to: .login(
            username: email,
            region: state.region,
            isLoginWithDeviceVisible: false
        ))
    }

    /// Builds an alert for region selection and navigates to the alert.
    ///
    private func presentRegionSelectionAlert() {
        let actions = RegionType.allCases.map { region in
            AlertAction(title: region.baseUrlDescription, style: .default) { [weak self] _ in
                self?.state.region = region
            }
        }
        let cancelAction = AlertAction(title: Localizations.cancel, style: .cancel)
        let alert = Alert(
            title: Localizations.loggingInOn,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: actions + [cancelAction]
        )
        coordinator.navigate(to: .alert(alert))
    }
}
