import AuthenticationServices
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
        stackNavigator: StackNavigator,
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: RootRoute, context: AnyObject?) {
        switch route {
        case .createPasskey:
            showCreatePasskey()
        case .cardAutofillForm:
            showCardAutofillForm()
        case .scenarioPicker:
            showScenarioPicker()
        case .simpleLoginForm:
            showSimpleLoginForm()
        }
    }

    func start() {
        // Nothing to do here - the initial route is set by the parent coordinator.
    }

    // MARK: Private Methods

    /// Shows the create passkey test screen.
    ///
    private func showCreatePasskey() {
        let processor = CreatePasskeyProcessor(coordinator: asAnyCoordinator(), delegate: self)
        let view = CreatePasskeyView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        stackNavigator?.push(viewController)
    }
    
    /// Shows the card autofill form test screen.
    ///
    private func showCardAutofillForm() {
        guard #available(iOS 17, *) else { return }
        let processor = CardAutofillFormProcessor(coordinator: asAnyCoordinator())
        let view = CardAutofillFormView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        stackNavigator?.push(viewController)
    }

    /// Shows the scenario picker screen.
    ///
    private func showScenarioPicker() {
        let processor = ScenarioPickerProcessor(coordinator: asAnyCoordinator())
        let view = ScenarioPickerView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }

    /// Shows the simple login form test screen.
    ///
    private func showSimpleLoginForm() {
        let processor = SimpleLoginFormProcessor(coordinator: asAnyCoordinator())
        let view = SimpleLoginFormView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        stackNavigator?.push(viewController)
    }
}

// MARK: - HasErrorAlertServices

extension RootCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}

// MARK: - CreatePasskeyProcessorDelegate

extension RootCoordinator: CreatePasskeyProcessorDelegate {
    func presentationAnchorForPasskeyRegistration() async -> ASPresentationAnchor {
        stackNavigator?.rootViewController?.view.window ?? UIWindow()
    }
}
