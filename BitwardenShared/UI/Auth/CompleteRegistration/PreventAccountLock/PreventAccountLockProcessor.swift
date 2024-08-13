// MARK: - PreventAccountLockProcessor

/// The processor used to manage state and handle actions for the prevent account lock screen.
///
class PreventAccountLockProcessor: StateProcessor<
    Void,
    PreventAccountLockAction,
    Void
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    // MARK: Initialization

    /// Creates a new `PreventAccountLockProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<AuthRoute, AuthEvent>) {
        self.coordinator = coordinator
        super.init(state: ())
    }

    // MARK: Methods

    override func perform(_: Void) async {}

    override func receive(_ action: PreventAccountLockAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismissPresented)
        }
    }
}
