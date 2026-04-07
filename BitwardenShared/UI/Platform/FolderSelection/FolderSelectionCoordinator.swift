import BitwardenKit
import UIKit
import UniformTypeIdentifiers

// MARK: - FolderSelectionCoordinator

/// A coordinator that manages navigation for folder selection.
///
@MainActor
class FolderSelectionCoordinator: NSObject, Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter

    // MARK: Properties

    /// The delegate for this coordinator.
    weak var delegate: FolderSelectionDelegate?

    /// The services used by this coordinator.
    let services: Services

    /// The navigator that is used to present each of the flows within this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `FolderSelectionCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator.
    ///   - services: The services for this coordinator.
    ///   - stackNavigator: The navigator that is used to present each of the flows within this
    ///     coordinator. This navigator should be one already used in the coordinator that is
    ///     presenting this coordinator, since this navigator is purely used to present other flows
    ///     modally.
    ///
    init(
        delegate: FolderSelectionDelegate,
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: Never, context: AnyObject?) {}

    func start() {
        showFolderBrowser()
    }

    // MARK: Private Methods

    /// Shows the folder browser screen.
    ///
    private func showFolderBrowser() {
        let viewController = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        viewController.allowsMultipleSelection = false
        viewController.delegate = self
        stackNavigator?.present(viewController)
    }
}

// MARK: - HasErrorAlertServices

extension FolderSelectionCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}

// MARK: - FolderSelectionCoordinator:UIDocumentPickerDelegate

extension FolderSelectionCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: UI.animated)
        guard let url = urls.first else { return }
        delegate?.folderSelectionCompleted(folderURL: url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: UI.animated)
    }
}
