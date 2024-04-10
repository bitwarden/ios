import OSLog
import SwiftUI

// MARK: - AuthenticatorItemCoordinator

/// A coordinator that manages navigation for displaying, editing, and adding individual tokens.
///
class AuthenticatorItemCoordinator: NSObject, Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = AuthenticatorItemModule

    typealias Services = HasErrorReporter
        & HasTimeProvider
        & ViewTokenProcessor.Services

    // MARK: - Private Properties

    /// The module used by this coordinator to create child coordinators.
    private let module: Module

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `AuthenticatorItemCoordinator`.
    ///
    /// - Parameters:
    ///   - module: The module used by this coordinator to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        module: Module,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func handleEvent(_ event: AuthenticatorItemEvent, context: AnyObject?) async {}

    func navigate(to route: AuthenticatorItemRoute, context: AnyObject?) {
        switch route {
        case let .alert(alert):
            stackNavigator?.present(alert)
        case let .dismiss(onDismiss):
            stackNavigator?.dismiss(animated: true, completion: {
                onDismiss?.action()
            })
        case let .editAuthenticatorItem(authenticatorItemView):
            Logger.application.log("Edit item \(authenticatorItemView.id)")
            showEditAuthenticatorItem(for: authenticatorItemView)
        case let .viewToken(id):
            Logger.application.log("View token \(id)")
            showViewToken(id: id)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Present a child `AuthenticatorItemCoordinator` on top of the existing coordinator.
    ///
    /// Presenting a view on top of an already presented view within the same coordinator causes
    /// problems when dismissing only the top view. So instead, present a new coordinator and
    /// show the view to navigate to within that coordinator's navigator.
    ///
    /// - Parameter route: The route to navigate to in the presented coordinator.
    ///
    private func presentChildAuthenticatorItemCoordinator(route: AuthenticatorItemRoute, context: AnyObject?) {
        let navigationController = UINavigationController()
        let coordinator = module.makeAuthenticatorItemCoordinator(stackNavigator: navigationController)
        coordinator.navigate(to: route, context: context)
        coordinator.start()
        stackNavigator?.present(navigationController)
    }

    /// Shows the edit token screen.
    ///
    /// - Parameters:
    ///   - token: The `Token` to edit.
    ///
    private func showEditAuthenticatorItem(for authenticatorItemView: AuthenticatorItemView) {
        guard let stackNavigator else { return }
        if stackNavigator.isEmpty {
            guard let state = AuthenticatorItemState(existing: authenticatorItemView)
            else { return }

            let processor = EditAuthenticatorItemProcessor(
                coordinator: asAnyCoordinator(),
                services: services,
                state: state
            )
            let store = Store(processor: processor)
            let view = EditAuthenticatorItemView(store: store)
            stackNavigator.replace(view)
        } else {
            presentChildAuthenticatorItemCoordinator(
                route: .editAuthenticatorItem(authenticatorItemView),
                context: self
            )
        }
    }

    /// Shows the view token screen.
    ///
    /// - Parameters:
    ///   - id: The id of the token to show.
    ///   - delegate: The delegate.
    ///
    private func showViewToken(id: String) {
        let processor = ViewTokenProcessor(
            coordinator: asAnyCoordinator(),
            itemId: id,
            services: services,
            state: ViewTokenState()
        )
        let store = Store(processor: processor)
        let view = ViewTokenView(
            store: store,
            timeProvider: services.timeProvider
        )
        stackNavigator?.replace(view)
    }
}
