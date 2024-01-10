import SwiftUI

// MARK: - SendCoordinator

/// A coordinator that manages navigation in the send tab.
///
final class SendCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasSendRepository

    // MARK: Properties

    /// The services used by this processor.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `SendCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this processor.
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

    func navigate(to route: SendRoute, context: AnyObject?) {
        switch route {
        case .addItem:
            showAddItem()
        case .dismiss:
            stackNavigator.dismiss()
        case .list:
            showList()
        }
    }

    func start() {
        navigate(to: .list)
    }

    // MARK: Private methods

    /// Shows the add item screen.
    ///
    private func showAddItem() {
        let state = AddEditSendItemState()
        let processor = AddEditSendItemProcessor(
            coordinator: self,
            services: services,
            state: state
        )
        let view = AddEditSendItemView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator.present(navigationController)
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
