import BitwardenKit
import Foundation

/// A coordinator that manages navigation for the Credential Exchange import flow.
///
class ImportCXFCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasImportCiphersRepository
        & HasPolicyService
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
        stackNavigator: StackNavigator,
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(
        to route: ImportCXFRoute,
        context: AnyObject?,
    ) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case let .importCredentials(credentialImportToken):
            showImportCXF(credentialImportToken: credentialImportToken)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Configures and displays the Credential Exchange import view.
    private func showImportCXF(credentialImportToken: UUID) {
        let processor = ImportCXFProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: ImportCXFState(credentialImportToken: credentialImportToken),
        )

        let view = ImportCXFView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension ImportCXFCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
