import Foundation

/// A coordinator that manages navigation for the Credential Exchange import flow.
///
class ImportCXPCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasImportCiphersRepository
        & HasStateService

    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `ImportCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(
        to route: ImportCXPRoute,
        context: AnyObject?
    ) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case let .importCredentials(credentialImportToken):
            showImportCXP(credentialImportToken: credentialImportToken)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Configures and displays the Credential Exchange import view.
    private func showImportCXP(credentialImportToken: UUID) {
        let processor = ImportCXPProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: ImportCXPState(credentialImportToken: credentialImportToken)
        )

        let view = ImportCXPView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}
