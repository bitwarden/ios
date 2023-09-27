// MARK: - LoginProcessor

/// The processor used to manage state and handle actions for the login screen.
///
class LoginProcessor: StateProcessor<LoginState, LoginAction, LoginEffect> {
    // MARK: Types

    typealias Services = HasAccountAPIService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<AuthRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `LoginProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: LoginState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: LoginEffect) async {
        switch effect {
        case .loginWithMasterPasswordPressed:
            await loginWithMasterPassword()
        }
    }

    override func receive(_ action: LoginAction) {
        switch action {
        case .enterpriseSingleSignOnPressed:
            coordinator.navigate(to: .enterpriseSingleSignOn)
        case .getMasterPasswordHintPressed:
            coordinator.navigate(to: .masterPasswordHint)
        case .loginWithDevicePressed:
            coordinator.navigate(to: .loginWithDevice)
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

    // MARK: Private Methods

    /// Attempts to log the user in with the email address and password values found in `state`.
    ///
    private func loginWithMasterPassword() async {
        do {
            _ = try await services.accountAPIService.preLogin(email: state.username)
            coordinator.navigate(to: .complete)
            // Encrypt the password with the kdf algorithm and send it to the server for verification: BIT-420
        } catch {
            // Error handling will be added in BIT-387
        }
    }
}
