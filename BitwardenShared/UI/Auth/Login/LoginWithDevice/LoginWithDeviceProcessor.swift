// MARK: - LoginWithDeviceProcessor

/// The processor used to manage state and handle actions for the `LoginWithDeviceView`
final class LoginWithDeviceProcessor: StateProcessor<
    LoginWithDeviceState,
    LoginWithDeviceAction,
    LoginWithDeviceEffect
> {
    // MARK: Properties

    /// The coordinator used for navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    // MARK: Initialization

    /// Initializes an `LoginWithDeviceProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        state: LoginWithDeviceState
    ) {
        self.coordinator = coordinator

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: LoginWithDeviceEffect) async {}

    override func receive(_ action: LoginWithDeviceAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }
}
