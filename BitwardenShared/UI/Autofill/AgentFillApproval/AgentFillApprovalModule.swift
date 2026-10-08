import BitwardenKit
import Foundation

// MARK: - AgentFillApprovalModule

/// An object that builds coordinators for the agent fill approval flow.
///
@MainActor
protocol AgentFillApprovalModule {
    /// Initializes a coordinator for navigating between `AgentFillApprovalRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `AgentFillApprovalRoute`s.
    ///
    func makeAgentFillApprovalCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<AgentFillApprovalRoute, Void>
}

extension DefaultAppModule: AgentFillApprovalModule {
    func makeAgentFillApprovalCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<AgentFillApprovalRoute, Void> {
        AgentFillApprovalCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        )
        .asAnyCoordinator()
    }
}
