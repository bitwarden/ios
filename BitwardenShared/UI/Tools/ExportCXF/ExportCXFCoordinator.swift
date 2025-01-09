import AuthenticationServices
import Foundation
import SwiftUI

/// A coordinator that manages navigation for the Credential Exchange export flow.
///
class ExportCXFCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasExportCXFCiphersRepository
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `ExportCXFCoordinator`.
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
        to route: ExportCXFRoute,
        context: AnyObject?
    ) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        }
    }

    func start() {
        showExportCXP()
    }

    // MARK: Private Methods

    private func showExportCXP() {
        let processor = ExportCXFProcessor(
            coordinator: asAnyCoordinator(),
            delegate: self,
            services: services,
            state: ExportCXFState()
        )
        let view = ExportCXFView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - ExportCXFProcessorDelegate

extension ExportCXFCoordinator: ExportCXFProcessorDelegate {
    func presentationAnchorForASCredentialExportManager() -> ASPresentationAnchor {
        stackNavigator?.rootViewController?.view.window ?? UIWindow()
    }
}
