import BitwardenKit

/// A coordinator that manages navigation for the agent fill approval screen.
///
final class AgentFillApprovalCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAgentFillApprovalRepository
        & HasAuthRepository
        & HasBiometricsService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter

    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `AgentFillApprovalCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: AgentFillApprovalRoute, context: AnyObject?) {
        switch route {
        case let .approval(id):
            showApproval(id: id, delegate: context as? AgentFillApprovalDelegate)
        case let .dismiss(onDismiss):
            stackNavigator?.dismiss(animated: true, completion: {
                onDismiss?.action()
            })
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the agent fill approval screen.
    ///
    /// - Parameters:
    ///   - id: The ID of the approval request to show.
    ///   - delegate: The delegate for the screen.
    ///
    private func showApproval(id: String, delegate: AgentFillApprovalDelegate?) {
        let processor = AgentFillApprovalProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: AgentFillApprovalState(approvalId: id),
        )
        let view = AgentFillApprovalView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension AgentFillApprovalCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
