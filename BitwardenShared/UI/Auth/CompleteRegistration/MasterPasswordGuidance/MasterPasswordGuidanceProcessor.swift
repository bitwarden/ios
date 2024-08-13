// MARK: - MasterPasswordGuidanceProcessor

/// The processor used to manage state and handle actions for the master password guidance screen.
///
class MasterPasswordGuidanceProcessor: StateProcessor<
    Void,
    MasterPasswordGuidanceAction,
    Void
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    // MARK: Initialization

    /// Creates a new `CompleteRegistrationProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<AuthRoute, AuthEvent>) {
        self.coordinator = coordinator
        super.init(state: ())
    }

    // MARK: Methods

    override func perform(_: Void) async {}

    override func receive(_ action: MasterPasswordGuidanceAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismissPresented)
        case .generatePasswordPressed:
            // TODO: PM-10267
            break
        }
    }
}
