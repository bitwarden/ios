import UIKit

// MARK: - SelectLanguageCoordinator

/// A coordinator that manages navigation for the Select Language UX.
///
public final class SelectLanguageCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    public typealias Services = HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasLanguageStateService

    /// The delegate for handling the selection flow.
    private weak var delegate: SelectLanguageDelegate?

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    public private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `SelectLanguageCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    public init(
        delegate: SelectLanguageDelegate?,
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    public func navigate(to route: SelectLanguageRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case .open(let currentLanguage):
            let processor = SelectLanguageProcessor(
                coordinator: asAnyCoordinator(),
                delegate: delegate,
                services: services,
                state: SelectLanguageState(currentLanguage: currentLanguage),
            )
        }
    }

    public func start() {}
}

// MARK: - HasErrorAlertServices

extension SelectLanguageCoordinator: HasErrorAlertServices {
    public var errorAlertServices: ErrorAlertServices { services }
}
