// MARK: - SingleSignOnProcessor

/// The processor used to manage state and handle actions for the `SingleSignOnView`.
///
final class SingleSignOnProcessor: StateProcessor<SingleSignOnState, SingleSignOnAction, SingleSignOnEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<AuthRoute>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `SingleSignOnProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute>,
        services: Services,
        state: SingleSignOnState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SingleSignOnEffect) async {
        switch effect {
        case .loginTapped:
            await handleLoginTapped()
        }
    }

    override func receive(_ action: SingleSignOnAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .identifierTextChanged(newValue):
            state.identifierText = newValue
        }
    }

    // MARK: Private Methods

    /// Handle attempting to login.
    private func handleLoginTapped() async {}
}
