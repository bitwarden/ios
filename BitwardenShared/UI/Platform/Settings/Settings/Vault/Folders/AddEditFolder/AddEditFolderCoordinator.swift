import BitwardenKit
import BitwardenSdk
import SwiftUI

// MARK: - AddEditFolderCoordinator

/// A coordinator that manages navigation for the add and edit folder view.
///
class AddEditFolderCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasSettingsRepository

    // MARK: Properties

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `AddEditFolderCoordinator`.
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

    func navigate(to route: AddEditFolderRoute, context: AnyObject?) {
        switch route {
        case let .addEditFolder(folder):
            showAddEditFolder(folder, delegate: context as? AddEditFolderDelegate)
        case .dismiss:
            stackNavigator?.dismiss()
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the add or edit folder screen.
    ///
    /// - Parameter folder: The existing folder to edit, if applicable.
    ///
    private func showAddEditFolder(_ folder: FolderView?, delegate: AddEditFolderDelegate?) {
        let mode: AddEditFolderState.Mode = if let folder { .edit(folder) } else { .add }
        let processor = AddEditFolderProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: AddEditFolderState(folderName: folder?.name ?? "", mode: mode),
        )
        let view = AddEditFolderView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension AddEditFolderCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
