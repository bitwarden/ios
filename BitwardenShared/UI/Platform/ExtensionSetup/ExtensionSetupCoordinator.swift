// MARK: - ExtensionSetupCoordinator

/// A coordinator that manages navigation in the vault tab.
///
final class ExtensionSetupCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasConfigService

    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `ExtensionSetupCoordinator`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: ExtensionSetupRoute, context: AnyObject?) {
        switch route {
        case let .extensionActivation(extensionType):
            showExtensionActivation(extensionType: extensionType)
        }
    }

    func start() {}

    // MARK: Private

    /// Shows the extension activation route.
    ///
    private func showExtensionActivation(extensionType: ExtensionActivationType) {
        let processor = ExtensionActivationProcessor(
            appExtensionDelegate: appExtensionDelegate,
            services: services,
            state: ExtensionActivationState(extensionType: extensionType)
        )
        let view = ExtensionActivationView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}
