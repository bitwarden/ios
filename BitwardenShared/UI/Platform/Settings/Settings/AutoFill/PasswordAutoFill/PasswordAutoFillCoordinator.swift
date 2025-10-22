import BitwardenKit
import SwiftUI

// MARK: - PasswordAutoFillCoordinatorDelegate

/// An object that is notified when external navigation actions need to occur from within the
/// password autofill flow.
///
protocol PasswordAutoFillCoordinatorDelegate: AnyObject {
    /// The user has completed authentication.
    ///
    func didCompleteAuth()
}

// MARK: - PasswordAutoFillCoordinator

/// A coordinator that manages navigation for the password autofill flow.
///
class PasswordAutoFillCoordinator: NSObject, Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAutofillCredentialService
        & HasConfigService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasNotificationCenterService
        & HasStateService

    // MARK: Private Properties

    /// The delegate for this coordinator, used to notify when external navigation actions need to occur.
    private weak var delegate: PasswordAutoFillCoordinatorDelegate?

    /// The services used by this coordinator.
    private let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `VaultCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator, used to notify when external navigation
    ///     actions need to occur.
    ///   - module: The module used by this coordinator to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: PasswordAutoFillCoordinatorDelegate?,
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    func handleEvent(_ event: PasswordAutofillEvent, context: AnyObject?) async {
        switch event {
        case .didCompleteAuth:
            delegate?.didCompleteAuth()
        }
    }

    func navigate(to route: PasswordAutofillRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.pop()
        case let .passwordAutofill(mode):
            showPasswordAutoFill(mode: mode)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the password auto-fill screen.
    ///
    private func showPasswordAutoFill(mode: PasswordAutoFillState.Mode) {
        let processor = PasswordAutoFillProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: PasswordAutoFillState(mode: mode),
        )
        let view = PasswordAutoFillView(store: Store(processor: processor))
        stackNavigator?.push(view)
    }
}

// MARK: - HasErrorAlertServices

extension PasswordAutoFillCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
