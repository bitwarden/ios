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
        case .registerPasskey:
            showCreatePasskey()
        case .cardAutofillForm:
            showCardAutofillForm()
        case .fileShare:
            showFileShare()
        case .managePasskeys:
            showManagePasskeys()
        case .scenarioPicker:
            showScenarioPicker()
        case .simpleLoginForm:
            showSimpleLoginForm()
        case .usePasskey:
            showUsePasskey()
        case .totpAutofillForm:
            showTOTPAutofillForm()
        }
    }

    func start() {
        // Nothing to do here - the initial route is set by the parent coordinator.
    }

    // MARK: Private Methods

    /// Shows the create passkey test screen.
    ///
    private func showCreatePasskey() {
        let processor = CreatePasskeyProcessor(
            coordinator: asAnyCoordinator(),
            delegate: self,
            passkeyRegistryService: services.passkeyRegistryService,
        )
        let view = CreatePasskeyView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        stackNavigator?.push(viewController)
    }

    /// Shows the manage passkeys screen.
    ///
    private func showManagePasskeys() {
        let processor = ManagePasskeysProcessor(
            coordinator: asAnyCoordinator(),
            passkeyRegistryService: services.passkeyRegistryService,
        )
        let view = ManagePasskeysView(store: Store(processor: processor))
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

    /// Shows the file share test screen.
    ///
    private func showFileShare() {
        guard #available(iOS 16.0, *) else { return }
        let processor = FileShareProcessor(coordinator: asAnyCoordinator())
        let view = FileShareView(store: Store(processor: processor))
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

    /// Shows the use passkey test screen.
    ///
    private func showUsePasskey() {
        let processor = UsePasskeyProcessor(coordinator: asAnyCoordinator(), delegate: self)
        let view = UsePasskeyView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        stackNavigator?.push(viewController)
    }

    /// Shows the TOTP autofill form test screen.
    ///
    private func showTOTPAutofillForm() {
        let processor = TOTPAutofillFormProcessor(coordinator: asAnyCoordinator())
        let view = TOTPAutofillFormView(store: Store(processor: processor))
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

// MARK: - UsePasskeyProcessorDelegate

extension RootCoordinator: UsePasskeyProcessorDelegate {
    func presentationAnchorForPasskeyAssertion() async -> ASPresentationAnchor {
        stackNavigator?.rootViewController?.view.window ?? UIWindow()
    }
}
