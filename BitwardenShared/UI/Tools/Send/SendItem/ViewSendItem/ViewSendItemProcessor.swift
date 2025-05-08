// MARK: - ViewSendItemProcessor

/// The processor used to manage state and handle actions for the view send item screen.
///
class ViewSendItemProcessor: StateProcessor<ViewSendItemState, ViewSendItemAction, ViewSendItemEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation for this processor.
    private let coordinator: AnyCoordinator<SendItemRoute, AuthAction>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `ViewSendItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation for this processor.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: AnyCoordinator<SendItemRoute, AuthAction>,
        services: Services,
        state: ViewSendItemState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ViewSendItemEffect) async {}

    override func receive(_ action: ViewSendItemAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .cancel)
        case .editItem:
            break
        }
    }
}
