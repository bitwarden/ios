// MARK: LoginProcessor

/// The processor used to manage state and handle actions for the login screen.
///
class LoginProcessor: StateProcessor<LoginState, LoginAction, Void> {
    // MARK: Private Properties

    private var coordinator: AnyCoordinator<AuthRoute>

    // MARK: Initialization

    /// Creates a new `LoginProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(coordinator: AnyCoordinator<AuthRoute>, state: LoginState) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: LoginAction) {
        switch action {
        case .enterpriseSingleSignOnPressed:
            coordinator.navigate(to: .enterpriseSingleSignOn)
        case .getMasterPasswordHintPressed:
            coordinator.navigate(to: .masterPasswordHint)
        case .loginWithDevicePressed:
            coordinator.navigate(to: .loginWithDevice)
        case .loginWithMasterPasswordPressed:
            // Add login functionality here: BIT-132
            print("login with master password")
        case let .masterPasswordChanged(newValue):
            state.masterPassword = newValue
        case .morePressed:
            coordinator.navigate(to: .loginOptions)
        case .notYouPressed:
            coordinator.navigate(to: .landing)
        case .revealMasterPasswordFieldPressed:
            state.isMasterPasswordRevealed.toggle()
        }
    }
}
