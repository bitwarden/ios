import Combine

// MARK: - RegionSelectionDelegate

/// A protocol for an object that is notified on region selection events.
///
protocol RegionSelectionDelegate: AnyObject {
    /// A new region has been selected.
    ///
    /// - Parameter region: The new region that was selected.
    ///
    func regionSelected(_ region: RegionType)
}

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
            coordinator.navigate(to: .regionSelection, context: self)
        case let .rememberMeChanged(newValue):
            state.isRememberMeOn = newValue
        }
    }

    // MARK: Private Methods

    /// Validate the currently entered email address and navigate to the login screen.
    ///
    private func validateEmailAndContinue() {
        guard state.email.isValidEmail else {
            let alert = Alert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.invalidEmail,
                alertActions: [
                    AlertAction(title: Localizations.ok, style: .default),
                ]
            )
            coordinator.navigate(to: .alert(alert))
            return
        }

        // Region placeholder until region selection support is added: BIT-268
        coordinator.navigate(to: .login(
            username: state.email,
            region: state.region,
            isLoginWithDeviceVisible: false
        ))
    }
}

extension LandingProcessor: RegionSelectionDelegate {
    func regionSelected(_ region: RegionType) {
        state.region = region
    }
}
