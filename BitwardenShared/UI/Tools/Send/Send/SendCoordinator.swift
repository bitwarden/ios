import BitwardenResources
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

    typealias Module = NavigatorBuilderModule
        & SendItemCoordinator.Module
        & SendItemModule

    typealias Services = HasConfigService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasPasteboardService
        & HasPolicyService
        & HasSendRepository
        & HasVaultRepository

    // MARK: - Private Properties

    /// The most recent coordinator used to navigate to a `FileSelectionRoute`. Used to keep the
    /// coordinator in memory.
    private var fileSelectionCoordinator: AnyCoordinator<FileSelectionRoute, Void>?

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
        case let .addItem(type):
            guard let delegate = context as? SendItemDelegate else { return }
            let route: SendItemRoute = if let type {
                .add(content: .type(type))
            } else {
                .add(content: nil)
            }
            showItem(route: route, delegate: delegate)
        case let .dismiss(dismissAction):
            stackNavigator?.dismiss(completion: dismissAction?.action)
        case let .editItem(sendView):
            guard let delegate = context as? SendItemDelegate else { return }
            showItem(route: .edit(sendView), delegate: delegate)
        case let .group(type):
            showGroup(type)
        case .list:
            showList()
        case let .share(url):
            showShareSheet(for: [url])
        case let .viewItem(sendView):
            guard let delegate = context as? SendItemDelegate else { return }
            showItem(route: .view(sendView), delegate: delegate)
        }
    }

    func start() {
        navigate(to: .list)
    }

    // MARK: Private methods

    /// Shows the group send screen.
    ///
    /// - Parameter type: The send type to display in this screen.
    ///
    private func showGroup(_ type: SendType) {
        let processor = SendListProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: SendListState(type: type)
        )
        let store = Store(processor: processor)
        let searchHandler = SendListSearchHandler(store: store)
        let view = SendListView(
            searchHandler: searchHandler,
            store: store
        )

        let viewController = UIHostingController(rootView: view)
        let searchController = UISearchController()
        searchController.searchBar.placeholder = Localizations.search
        searchController.searchResultsUpdater = searchHandler

        stackNavigator?.push(
            viewController,
            navigationTitle: type.localizedName,
            searchController: searchController
        )
    }

    /// Shows the provided send item route.
    ///
    /// - Parameters:
    ///   - route: The route to navigate to.
    ///   - delegate: The delegate for this navigation.
    ///
    private func showItem(route: SendItemRoute, delegate: SendItemDelegate) {
        let navigationController = module.makeNavigationController()
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

// MARK: - HasErrorAlertServices

extension SendCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
