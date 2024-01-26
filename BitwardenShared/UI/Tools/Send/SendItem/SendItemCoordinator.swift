import BitwardenSdk
import OSLog
import Photos
import PhotosUI
import SwiftUI

// MARK: - SendCoordinator

/// A coordinator that manages navigation in the send tab.
///
final class SendItemCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = FileSelectionModule

    typealias Services = HasErrorReporter
        & HasPasteboardService
        & HasSendRepository

    // MARK: - Private Properties

    /// The most recent coordinator used to navigate to a `FileSelectionRoute`. Used to keep the
    /// coordinator in memory.
    private var fileSelectionCoordinator: AnyCoordinator<FileSelectionRoute>?

    // MARK: Properties

    /// The delegate for this coordinator.
    weak var delegate: SendItemDelegate?

    /// The module used by this coordinator
    let module: Module

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `SendItemCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator.
    ///   - module: The module used by this coordinator.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: SendItemDelegate,
        module: Module,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: SendItemRoute, context: AnyObject?) {
        switch route {
        case let .add(hasPremium):
            showAddItem(hasPremium: hasPremium)
        case .cancel:
            delegate?.sendItemCancelled()
        case .deleted:
            delegate?.sendItemDeleted()
        case let .complete(sendView):
            delegate?.sendItemCompleted(with: sendView)
        case let .edit(sendView, hasPremium):
            showEditItem(for: sendView, hasPremium: hasPremium)
        case let .fileSelection(route):
            guard let delegate = context as? FileSelectionDelegate else { return }
            showFileSelection(route: route, delegate: delegate)
        case let .share(url):
            showShareSheet(for: [url])
        }
    }

    func start() {}

    // MARK: Private methods

    /// Shows the add item screen.
    ///
    /// - Parameter hasPremium: A flag indicating if the active account has premium access.
    ///
    private func showAddItem(hasPremium: Bool) {
        let state = AddEditSendItemState(
            hasPremium: hasPremium
        )
        let processor = AddEditSendItemProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )
        let view = AddEditSendItemView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }

    /// Shows the edit item screen.
    ///
    /// - Parameters:
    ///   - sendView: The send to edit.
    ///   - hasPremium: A flag indicating if the active account has premium access.
    ///
    private func showEditItem(for sendView: SendView, hasPremium: Bool) {
        let state = AddEditSendItemState(
            sendView: sendView,
            hasPremium: hasPremium
        )
        let processor = AddEditSendItemProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )
        let view = AddEditSendItemView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }

    /// Navigates to the specified `FileSelectionRoute`.
    ///
    /// - Parameters:
    ///   - route: The route to navigate to.
    ///   - delegate: The `FileSelectionDelegate` for this navigation.
    ///
    private func showFileSelection(
        route: FileSelectionRoute,
        delegate: FileSelectionDelegate
    ) {
        guard let stackNavigator else { return }
        let coordinator = module.makeFileSelectionCoordinator(
            delegate: delegate,
            stackNavigator: stackNavigator
        )
        coordinator.start()
        coordinator.navigate(to: route)
        fileSelectionCoordinator = coordinator
    }

    /// Presents the system share sheet for the specified items.
    ///
    /// - Parameter items: The items to share using the system share sheet.
    ///
    private func showShareSheet(for items: [Any]) {
        let viewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        stackNavigator?.present(viewController)
    }
}
