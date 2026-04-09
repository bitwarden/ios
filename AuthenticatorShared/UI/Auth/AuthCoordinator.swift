import BitwardenKit
import OSLog
import SwiftUI

// MARK: - AuthCoordinatorDelegate

/// An object that is signaled when specific circumstances in the auth flow have been encountered.
///
@MainActor
protocol AuthCoordinatorDelegate: AnyObject {
    /// Called when the auth flow has been completed.
    ///
    func didCompleteAuth()
}

// MARK: - AuthCoordinator

/// A coordinator that manages navigation in the authentication flow.
///
final class AuthCoordinator: NSObject, Coordinator, HasStackNavigator, HasRouter {
    // MARK: Types

    typealias Router = AnyRouter<AuthEvent, AuthRoute>

    typealias Services = HasBiometricsRepository
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter

    // MARK: Properties

    /// The delegate for this coordinator. Used to signal when auth has been completed. This should
    /// be used by the coordinator to communicate to its parent coordinator when auth completes and
    /// the auth flow should be dismissed.
    private weak var delegate: (any AuthCoordinatorDelegate)?

    /// The root navigator used to display this coordinator's interface.
    weak var rootNavigator: (any RootNavigator)?

    /// The router used by this coordinator.
    var router: AnyRouter<AuthEvent, AuthRoute>

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `AuthCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator. Used to signal when auth has been completed.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - router: The router used by this coordinator to handle events.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: AuthCoordinatorDelegate,
        rootNavigator: RootNavigator,
        router: AnyRouter<AuthEvent, AuthRoute>,
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.delegate = delegate
        self.rootNavigator = rootNavigator
        self.router = router
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: AuthRoute, context: AnyObject?) {
        switch route {
        case .complete:
            if stackNavigator?.isPresenting == true {
                stackNavigator?.dismiss {
                    self.delegate?.didCompleteAuth()
                }
            } else {
                delegate?.didCompleteAuth()
            }
        case .vaultUnlock:
            showVaultUnlock()
        }
    }

    func start() {
        navigate(to: .vaultUnlock)
    }

    // MARK: Private Methods

    /// Shows the vault unlock view.
    ///
    /// - Parameters:
    ///   - account: The active account.
    ///   - animated: Whether to animate the transition.
    ///   - attemptAutomaticBiometricUnlock: Whether to the processor should attempt a biometric unlock on appear.
    ///   - didSwitchAccountAutomatically: A flag indicating if the active account was switched automatically.
    ///
    private func showVaultUnlock() {
        let processor = VaultUnlockProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultUnlockState(),
        )
        processor.shouldAttemptAutomaticBiometricUnlock = true
        let view = VaultUnlockView(store: Store(processor: processor))
        stackNavigator?.replace(view, animated: true)
    }
}

// MARK: - HasErrorAlertServices

extension AuthCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
