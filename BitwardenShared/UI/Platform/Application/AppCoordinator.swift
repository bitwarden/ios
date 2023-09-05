import UIKit

// MARK: - AppCoordinator

/// A coordinator that manages the app's top-level navigation.
///
public class AppCoordinator: Coordinator {
    // MARK: Properties

    /// The navigator to use for presenting screens.
    public let navigator: RootNavigator

    // MARK: Initialization

    /// Creates a new `AppCoordinator`.
    ///
    /// - Parameter navigator: The navigator to use for presenting screens.
    ///
    public init(navigator: RootNavigator) {
        self.navigator = navigator
    }

    // MARK: Methods

    public func navigate(to route: AppRoute, context: AnyObject?) {
        switch route {
        case .onboarding:
            showOnboarding()
        }
    }

    public func start() {
        showOnboarding()
    }

    // MARK: Private Methods

    /// Shows the onboarding navigator.
    private func showOnboarding() {
        // Temporary view controller for testing purposes. Will be replaced with real functionality in BIT-155
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBlue
        let navController = UINavigationController(rootViewController: viewController)
        navigator.show(child: navController)
    }
}
