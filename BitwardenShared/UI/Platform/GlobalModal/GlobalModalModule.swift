import BitwardenKit
import Foundation

// MARK: - GlobalModalModule

/// An object that builds coordinator for global modals.
@MainActor
public protocol GlobalModalModule {
    /// Initializes a coordinator for navigating between `GlobalModalRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for the global modals coordinator.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `GlobalModalRoute`s.
    ///
    func makeGlobalModalCoordinator(
//        delegate: GlobalModalCoordinatorDelegate,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<GlobalModalRoute, Void>
}
