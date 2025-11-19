import UIKit

// MARK: - NavigatorBuilderModule

/// An object that builds navigators for the application.
///
@MainActor
public protocol NavigatorBuilderModule: AnyObject {
    /// Builds a navigation controller for use in the application.
    ///
    /// - Returns: A navigation controller for use in the application.
    ///
    func makeNavigationController() -> UINavigationController
}
