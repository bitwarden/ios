import BitwardenKit
import Foundation

// MARK: - AgentAccessModule

/// An object that builds coordinators for the Agent Access flow.
///
@MainActor
protocol AgentAccessModule {
    /// Initializes a coordinator for navigating between `AgentAccessRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `AgentAccessRoute`s.
    ///
    func makeAgentAccessCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<AgentAccessRoute, Void>
}

extension DefaultAppModule: AgentAccessModule {
    func makeAgentAccessCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<AgentAccessRoute, Void> {
        AgentAccessCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        )
        .asAnyCoordinator()
    }
}
