import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AgentAccessCoordinator

/// A coordinator that manages navigation for the Agent Access screens.
///
final class AgentAccessCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAgentAccessRepository
        & HasAuthRepository
        & HasBiometricsService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasPasteboardService
        & HasUserVerificationHelperFactory

    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `AgentAccessCoordinator`.
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

    func navigate(to route: AgentAccessRoute, context: AnyObject?) {
        switch route {
        case let .approval(requestId):
            showApproval(requestId: requestId, delegate: context as? AgentAccessApprovalDelegate)
        case .auditLog:
            showAuditLog()
        case .back:
            stackNavigator?.pop()
        case .connections:
            showConnections()
        case let .dismiss(action):
            stackNavigator?.dismiss(completion: action?.action)
        case .home:
            showHome()
        case .pairing:
            showPairing()
        case let .share(text):
            showShareSheet(text)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the approval sheet content for a pending request.
    ///
    /// - Parameters:
    ///   - requestId: The ID of the pending request.
    ///   - delegate: The delegate that is notified when the request is answered.
    ///
    private func showApproval(requestId: String, delegate: AgentAccessApprovalDelegate?) {
        let processor = AgentAccessApprovalProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: AgentAccessApprovalState(requestId: requestId),
        )
        stackNavigator?.replace(AgentAccessApprovalView(store: Store(processor: processor)))
    }

    /// Shows the activity log.
    ///
    private func showAuditLog() {
        let processor = AgentAccessAuditLogProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AgentAccessAuditLogState(),
        )
        let view = AgentAccessAuditLogView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.agentAccessAuditLog)
    }

    /// Shows the list of paired agents.
    ///
    private func showConnections() {
        let processor = AgentAccessConnectionsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AgentAccessConnectionsState(),
        )
        let view = AgentAccessConnectionsView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.agentAccessConnections)
    }

    /// Shows the Agent Access home screen.
    ///
    private func showHome() {
        let processor = AgentAccessHomeProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AgentAccessHomeState(),
        )
        let view = AgentAccessHomeView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.agentAccess)
    }

    /// Shows the screen that pairs a new agent.
    ///
    private func showPairing() {
        let processor = AgentAccessPairingProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AgentAccessPairingState(),
        )
        let view = AgentAccessPairingView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.agentAccessPairAgent)
    }

    /// Shows the system share sheet.
    ///
    /// - Parameter text: The text to share.
    ///
    private func showShareSheet(_ text: String) {
        let viewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        stackNavigator?.present(viewController)
    }
}

// MARK: - HasErrorAlertServices

extension AgentAccessCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
