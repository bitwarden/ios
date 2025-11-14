import BitwardenKit
import Foundation

// MARK: - ProfileSwitcherCoordinator

/// A coordinator that manages navigation in the profile switcher.
/// In practice, it acts largely as a passthrough for the `ProfileSwitcherHandler` so as to
/// preserve flows in apps running on iOS pre-26.
final class ProfileSwitcherCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Service = HasAuthRepository
        & HasErrorAlertServices.ErrorAlertServices

    // MARK: Private Properties

    /// An object that handles `ProfileSwitcherView` actions and effects.
    private var handler: ProfileSwitcherHandler

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `ProfileSwitcherCoordinator`.
    ///
    /// - Parameters:
    ///   - handler: An object that handles `ProfileSwitcherView` actions and effects.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    init(
        handler: ProfileSwitcherHandler,
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.handler = handler
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: ProfileSwitcherRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case .open:
            let processor = ProfileSwitcherProcessor(
                coordinator: asAnyCoordinator(),
                handler: handler,
                services: services,
                state: handler.profileSwitcherState,
            )
            let store = Store(processor: processor)
            let view = ProfileSwitcherSheet(store: store)
            stackNavigator?.replace(view)
        }
    }

    func start() {}
}

// MARK: - HasErrorAlertServices

extension ProfileSwitcherCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
