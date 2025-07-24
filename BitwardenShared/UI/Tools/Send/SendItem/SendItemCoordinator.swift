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
        & NavigatorBuilderModule
        & SendItemModule

    typealias Services = HasAuthRepository
        & HasConfigService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasPasteboardService
        & HasPolicyService
        & HasReviewPromptService
        & HasSendRepository

    // MARK: - Private Properties

    /// The most recent coordinator used to navigate to a `FileSelectionRoute`. Used to keep the
    /// coordinator in memory.
    private var fileSelectionCoordinator: AnyCoordinator<FileSelectionRoute, Void>?

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

    func handleEvent(_ event: AuthAction, context: AnyObject?) async {
        await delegate?.handle(event)
    }

    func navigate(to route: SendItemRoute, context: AnyObject?) {
        switch route {
        case let .add(content):
            showAddItem(content: content)
        case .cancel:
            delegate?.sendItemCancelled()
        case .deleted:
            delegate?.sendItemDeleted()
        case let .dismiss(dismissAction):
            stackNavigator?.dismiss(completion: dismissAction?.action)
        case let .complete(sendView):
            delegate?.sendItemCompleted(with: sendView)
        case let .edit(sendView):
            showEditItem(for: sendView)
        case let .fileSelection(route):
            guard let delegate = context as? FileSelectionDelegate else { return }
            showFileSelection(route: route, delegate: delegate)
        case let .share(url):
            showShareSheet(for: [url])
        case let .view(sendView):
            showViewItem(for: sendView)
        }
    }

    func start() {}

    // MARK: Private methods

    /// Present a child `SendItemCoordinator` on top of the existing coordinator.
    ///
    /// Presenting a view on top of an already presented view within the same coordinator causes
    /// problems when dismissing only the top view. So instead, present a new coordinator and
    /// show the view to navigate to within that coordinator's navigator.
    ///
    /// - Parameter route: The route to navigate to in the presented coordinator.
    ///
    private func presentChildSendItemCoordinator(route: SendItemRoute, context: AnyObject?) {
        let navigationController = module.makeNavigationController()
        let coordinator = module.makeSendItemCoordinator(delegate: self, stackNavigator: navigationController)
        coordinator.navigate(to: route, context: context)
        coordinator.start()
        stackNavigator?.present(navigationController)
    }

    /// Shows the add item screen.
    ///
    /// - Parameter content: Optional content to pre-fill the add item screen.
    ///
    private func showAddItem(content: AddSendContentType?) {
        var state = AddEditSendItemState()
        switch content {
        case let .file(fileName, fileData):
            state.fileName = fileName
            state.fileData = fileData
            state.type = .file
            state.mode = .shareExtension(.empty())
        case let .text(text):
            state.text = text
            state.type = .text
            state.mode = .shareExtension(.empty())
        case let .type(type):
            state.type = type
            state.mode = .add
        case nil:
            break
        }
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
    /// - Parameter sendView: The send to edit.
    ///
    private func showEditItem(for sendView: SendView) {
        guard let stackNavigator else { return }
        if stackNavigator.isEmpty {
            let state = AddEditSendItemState(sendView: sendView)
            let processor = AddEditSendItemProcessor(
                coordinator: asAnyCoordinator(),
                services: services,
                state: state
            )
            let view = AddEditSendItemView(store: Store(processor: processor))
            stackNavigator.replace(view)
        } else {
            presentChildSendItemCoordinator(route: .edit(sendView), context: nil)
        }
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

    /// Shows the view item screen.
    ///
    /// - Parameter sendView: The send to view.
    ///
    private func showViewItem(for sendView: SendView) {
        let state = ViewSendItemState(sendView: sendView)
        let processor = ViewSendItemProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )
        stackNavigator?.replace(ViewSendItemView(store: Store(processor: processor)))
    }
}

// MARK: - HasErrorAlertServices

extension SendItemCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}

// MARK: - SendItemDelegate

extension SendItemCoordinator: SendItemDelegate {
    func handle(_ authAction: AuthAction) async {
        await delegate?.handle(authAction)
    }

    func sendItemCancelled() {
        stackNavigator?.dismiss()
    }

    func sendItemCompleted(with sendView: SendView) {
        // The dismiss and share sheet presentation needs to occur here rather than passing it onto
        // the delegate to handle the case where the edit view is presented on the view Send view.
        // The edit view is dismissed and the share sheet is presented on the view Send view.
        Task {
            do {
                guard let url = try await self.services.sendRepository.shareURL(for: sendView) else {
                    navigate(to: .dismiss(nil))
                    return
                }
                navigate(to: .dismiss(DismissAction {
                    self.navigate(to: .share(url: url))
                }))
            } catch {
                services.errorReporter.log(error: error)
                navigate(to: .dismiss(nil))
            }
        }
    }

    func sendItemDeleted() {
        delegate?.sendItemDeleted()
    }
}
