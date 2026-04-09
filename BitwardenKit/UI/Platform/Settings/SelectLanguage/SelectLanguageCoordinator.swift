import UIKit

// MARK: - SelectLanguageCoordinator

/// A coordinator that manages navigation for the Select Language UX.
///
public final class SelectLanguageCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    public typealias Services = HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasLanguageStateService

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
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    public func navigate(to route: SelectLanguageRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case let .open(currentLanguage):
            showSelectLanguage(
                currentLanguage: currentLanguage,
                delegate: context as? SelectLanguageDelegate,
            )
        }
    }

    public func start() {}

    /// Presents the Select Language view.
    ///
    /// - Parameters:
    ///   - currentLanguage: The currently selected language.
    ///   - delegate: The delegate for handling the selection flow.
    private func showSelectLanguage(
        currentLanguage: LanguageOption,
        delegate: SelectLanguageDelegate?,
    ) {
        let processor = SelectLanguageProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: SelectLanguageState(currentLanguage: currentLanguage),
        )
        stackNavigator?.present(SelectLanguageView(store: Store(processor: processor)))
    }
}

// MARK: - HasErrorAlertServices

extension SelectLanguageCoordinator: HasErrorAlertServices {
    public var errorAlertServices: ErrorAlertServices { services }
}
