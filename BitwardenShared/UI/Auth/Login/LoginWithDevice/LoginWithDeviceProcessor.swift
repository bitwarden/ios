// MARK: - LoginWithDeviceProcessor

/// The processor used to manage state and handle actions for the `LoginWithDeviceView`
final class LoginWithDeviceProcessor: StateProcessor<
    LoginWithDeviceState,
    LoginWithDeviceAction,
    LoginWithDeviceEffect
> {
    // MARK: Types

    typealias Services = HasAppIdService
        & HasAuthRepository

    // MARK: Properties

    /// The coordinator used for navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

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
        coordinator: AnyCoordinator<AuthRoute>,
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
        case .appeared:
            defer {
                coordinator.hideLoadingOverlay()
            }
            do {
                coordinator.showLoadingOverlay(title: Localizations.loading)

                let deviceId = await services.appIdService.getOrCreateAppId()
                let fingerprint = try await services.authRepository.initiateLoginWithDevice(
                    deviceId: deviceId,
                    email: state.email
                )
                state.fingerprintPhrase = fingerprint
            } catch {
                coordinator.navigate(to: .alert(.defaultAlert(title: Localizations.anErrorHasOccurred)))
            }
        }
    }

    override func receive(_ action: LoginWithDeviceAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }
}
