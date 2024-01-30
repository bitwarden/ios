// MARK: - LoginWithDeviceProcessor

/// The processor used to manage state and handle actions for the `LoginWithDeviceView`.
///
final class LoginWithDeviceProcessor: StateProcessor<
    LoginWithDeviceState,
    LoginWithDeviceAction,
    LoginWithDeviceEffect
> {
    // MARK: Types

    typealias Services = HasAuthService
        & HasErrorReporter

    // MARK: Properties

    /// The coordinator used for navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services used by this processor.
    let services: Services

    // MARK: Initialization

    /// Initializes an `LoginWithDeviceProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: LoginWithDeviceState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: LoginWithDeviceEffect) async {
        switch effect {
        case .appeared,
             .resendNotification:
            await sendLoginWithDeviceRequest()
        }
    }

    override func receive(_ action: LoginWithDeviceAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }

    // MARK: Private Methods

    /// Create and send the login with device notification and display the resulting fingerprint.
    ///
    private func sendLoginWithDeviceRequest() async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            coordinator.showLoadingOverlay(title: Localizations.loading)

            let fingerprint = try await services.authService.initiateLoginWithDevice(email: state.email)
            state.fingerprintPhrase = fingerprint
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }
}
