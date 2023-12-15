// MARK: - PasswordHintProcessor

/// The processor used to manage state and handle actions for the passwort hint screen.
///
class PasswordHintProcessor: StateProcessor<PasswordHintState, PasswordHintAction, PasswordHintEffect> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    // MARK: Initialization

    /// Creates a new `PasswordHintProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        state: PasswordHintState
    ) {
        self.coordinator = coordinator
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
        coordinator.showLoadingOverlay(title: Localizations.submitting)

        // TODO: BIT-733 Perform the password hint request
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let okAction = AlertAction(title: Localizations.ok, style: .default) { _, _ in
            self.coordinator.navigate(to: .dismiss)
        }
        let alert = Alert(
            title: "",
            message: Localizations.passwordHintAlert,
            alertActions: [okAction]
        )

        coordinator.hideLoadingOverlay()
        coordinator.navigate(to: .alert(alert))
    }
}
