import OSLog
import Photos
import PhotosUI
import SwiftUI

// MARK: - SendCoordinator

/// A coordinator that manages navigation in the send tab.
///
final class SendCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = FileSelectionModule

    typealias Services = HasErrorReporter
        & HasSendRepository

    // MARK: Properties

    /// The module used by this coordinator
    let module: Module

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

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
            showAddItem()
        case .camera:
            guard let delegate = context as? FileSelectionDelegate else { return }
            showFileSelection(route: .camera, delegate: delegate)
        case .dismiss:
            stackNavigator.dismiss()
        case .fileBrowser:
            guard let delegate = context as? FileSelectionDelegate else { return }
            showFileSelection(route: .file, delegate: delegate)
        case .list:
            showList()
        case .photoLibrary:
            guard let delegate = context as? FileSelectionDelegate else { return }
            showFileSelection(route: .photo, delegate: delegate)
        }
    }

    func start() {
        navigate(to: .list)
    }

    // MARK: Private methods

    /// Shows the add item screen.
    ///
    private func showAddItem() {
        Task {
            let hasPremium = try? await services.sendRepository.doesActiveAccountHavePremium()
            let state = AddEditSendItemState(
                hasPremium: hasPremium ?? false
            )
            let processor = AddEditSendItemProcessor(
                coordinator: self,
                state: state
            )
            let view = AddEditSendItemView(store: Store(processor: processor))
            let viewController = UIHostingController(rootView: view)
            let navigationController = UINavigationController(rootViewController: viewController)
            stackNavigator.present(navigationController)
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
        let coordinator = module.makeFileSelectionCoordinator(
            delegate: delegate,
            stackNavigator: stackNavigator
        )
        coordinator.start()
        coordinator.navigate(to: route)
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
        stackNavigator.replace(view)
    }
}
