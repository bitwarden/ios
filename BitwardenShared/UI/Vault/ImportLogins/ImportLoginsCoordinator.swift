import BitwardenKit
import SwiftUI

/// An object that is notified external navigation actions need to occur from within the import logins flow.
///
protocol ImportLoginsCoordinatorDelegate: AnyObject {
    /// The user has completed the import login flow.
    ///
    func didCompleteLoginsImport()
}

// MARK: - ImportLoginsCoordinator

/// A coordinator that manages navigation for the import logins flow.
///
class ImportLoginsCoordinator: NSObject, Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = ImportLoginsModule

    typealias Services = HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasSettingsRepository
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The delegate for this coordinator, used to notify when external navigation actions need to occur.
    private weak var delegate: ImportLoginsCoordinatorDelegate?

    /// The module used by this coordinator to create child coordinators.
    private let module: Module

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
        delegate: ImportLoginsCoordinatorDelegate,
        module: Module,
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.delegate = delegate
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    func handleEvent(_ event: ImportLoginsEvent, context: AnyObject?) async {
        switch event {
        case .completeImportLogins:
            delegate?.didCompleteLoginsImport()
        }
    }

    func navigate(to route: ImportLoginsRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case let .importLogins(mode):
            showImportLogins(mode: mode)
        case .importLoginsSuccess:
            showImportLoginsSuccess()
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the import login items screen.
    ///
    /// - Parameter mode: The mode of the view based on where the flow was started from.
    ///
    private func showImportLogins(mode: ImportLoginsState.Mode) {
        let processor = ImportLoginsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: ImportLoginsState(mode: mode),
        )
        let view = ImportLoginsView(store: Store(processor: processor))
        stackNavigator?.push(view)
    }

    /// Shows the import login success screen.
    ///
    private func showImportLoginsSuccess() {
        let processor = ImportLoginsSuccessProcessor(coordinator: asAnyCoordinator())
        let view = ImportLoginsSuccessView(store: Store(processor: processor))
        stackNavigator?.present(view, isModalInPresentation: true)
    }
}

// MARK: - HasErrorAlertServices

extension ImportLoginsCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
