import BitwardenKit
import SwiftUI
import UIKit

// MARK: - RootCoordinator

/// A coordinator that manages navigation in the root flow of test scenarios.
///
@MainActor
class RootCoordinator: Coordinator, HasStackNavigator {
    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    /// The stack navigator used to display screens.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `RootCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator used to display screens.
    ///
    init(
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: RootRoute, context: AnyObject?) {
        switch route {
        case .testList:
            showTestList()
        case .passwordAutofill:
            showPasswordAutofill()
        }
    }

    func start() {
        // Nothing to do here - the initial route is set by the parent coordinator.
    }

    // MARK: Private Methods

    /// Shows the test list screen.
    ///
    private func showTestList() {
        let processor = TestListProcessor(coordinator: asAnyCoordinator())
        let view = TestListView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }

    /// Shows the password autofill test screen.
    ///
    private func showPasswordAutofill() {
        let processor = PasswordAutofillProcessor(coordinator: asAnyCoordinator())
        let view = PasswordAutofillView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        stackNavigator?.push(viewController)
    }
}

// MARK: - HasErrorAlertServices

extension RootCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
