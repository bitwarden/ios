import BitwardenKit
import Foundation

/// A protocol for an object that contains the dependencies for creating coordinators in the root flow.
///
@MainActor
protocol RootModule: AnyObject {
    /// Creates a `RootCoordinator`.
    ///
    /// - Parameter stackNavigator: The stack navigator to use for presenting screens.
    /// - Returns: A `RootCoordinator` instance.
    ///
    func makeRootCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<RootRoute, Void>
}
