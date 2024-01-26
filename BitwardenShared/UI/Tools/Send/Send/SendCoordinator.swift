import BitwardenSdk
import OSLog
import Photos
import PhotosUI
import SwiftUI

// MARK: - SendCoordinator

/// A coordinator that manages navigation in the send tab.
///
final class SendCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = SendItemCoordinator.Module
        & SendItemModule

    typealias Services = HasErrorReporter
        & HasPasteboardService
        & HasSendRepository

    // MARK: - Private Properties

    /// The most recent coordinator used to navigate to a `FileSelectionRoute`. Used to keep the
    /// coordinator in memory.
    private var fileSelectionCoordinator: AnyCoordinator<FileSelectionRoute>?

    // MARK: Properties

    /// The module used by this coordinator
    let module: Module

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `SendCoordinator`.
    ///
    /// - Parameters:
    ///   - module: The module used by this coordinator.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        module: Module,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: SendRoute, context: AnyObject?) {
        switch route {
        case .addItem:
            guard let delegate = context as? SendItemDelegate else { return }
            Task {
                let hasPremium = try? await services.sendRepository.doesActiveAccountHavePremium()
                showItem(route: .add(hasPremium: hasPremium ?? false), delegate: delegate)
            }
        case let .dismiss(dismissAction):
            stackNavigator?.dismiss(completion: dismissAction?.action)
        case let .editItem(sendView):
            guard let delegate = context as? SendItemDelegate else { return }
            Task {
                let hasPremium = try? await services.sendRepository.doesActiveAccountHavePremium()
                showItem(route: .edit(sendView, hasPremium: hasPremium ?? false), delegate: delegate)
            }
        case .list:
            showList()
        case let .share(url):
            showShareSheet(for: [url])
        }
    }

    func start() {
        navigate(to: .list)
    }

    // MARK: Private methods

    /// Shows the provided send item route.
    ///
    /// - Parameters:
    ///   - route: The route to navigate to.
    ///   - delegate: The delegate for this navigation.
    ///
    private func showItem(route: SendItemRoute, delegate: SendItemDelegate) {
        let navigationController = UINavigationController()
        let coordinator = module.makeSendItemCoordinator(
            delegate: delegate,
            stackNavigator: navigationController
        )
        coordinator.start()
        coordinator.navigate(to: route)
        stackNavigator?.present(navigationController)
    }

    /// Shows the list of sends.
    ///
    private func showList() {
        let processor = SendListProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: SendListState()
        )
        let store = Store(processor: processor)
        let view = SendListView(store: store)
        stackNavigator?.replace(view)
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
