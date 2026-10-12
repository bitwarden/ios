import Foundation

/// An object that is notified when the debug menu is dismissed.
///
public protocol DebugMenuCoordinatorDelegate: AnyObject { // sourcery: AutoMockable
    /// The debug menu has been dismissed.
    ///
    func didDismissDebugMenu()
}

/// A coordinator that manages navigation for the debug menu.
///
public final class DebugMenuCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    public typealias Services = HasConfigService
        & HasDebugStateService
        & HasEnvironmentService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasServerCommunicationConfigClientSingleton

    // MARK: Private Properties

    /// The delegate for this coordinator, which is notified when the debug menu is dismissed.
    private weak var delegate: DebugMenuCoordinatorDelegate?

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    public private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `DebugMenuCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator, which is notified when the debug menu is dismissed.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    public init(
        delegate: DebugMenuCoordinatorDelegate,
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    public func navigate(
        to route: DebugMenuRoute,
        context: AnyObject?,
    ) {
        switch route {
        case .addFillAssistRule:
            showAddFillAssistRule()
        case .dismiss:
            stackNavigator?.dismiss {
                self.delegate?.didDismissDebugMenu()
            }
        case .dismissAddFillAssistRule:
            stackNavigator?.dismiss()
        }
    }

    /// Starts the process of displaying the debug menu.
    public func start() {
        showDebugMenu()
    }

    // MARK: Private Methods

    /// Shows the screen for adding a Fill Assist debug rule.
    private func showAddFillAssistRule() {
        let processor = AddFillAssistRuleProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AddFillAssistRuleState(),
        )
        stackNavigator?.present(AddFillAssistRuleView(store: Store(processor: processor)))
    }

    /// Configures and displays the debug menu.
    private func showDebugMenu() {
        let processor = DebugMenuProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: DebugMenuState(),
        )

        let view = DebugMenuView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension DebugMenuCoordinator: HasErrorAlertServices {
    public var errorAlertServices: ErrorAlertServices { services }
}
