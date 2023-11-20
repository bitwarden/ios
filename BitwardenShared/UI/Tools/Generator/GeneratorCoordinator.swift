import SwiftUI

/// A coordinator that manages navigation in the generator tab.
///
final class GeneratorCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasGeneratorRepository
        & HasPasteboardService

    // MARK: Properties

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `GeneratorCoordinator`.
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

    func navigate(to route: GeneratorRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator.dismiss()
        case .generator:
            showGenerator()
        case .generatorHistory:
            showGeneratorHistory()
        }
    }

    func start() {
        navigate(to: .generator)
    }

    // MARK: Private Methods

    /// Shows the generator screen.
    ///
    private func showGenerator() {
        let processor = GeneratorProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: GeneratorState()
        )
        let view = GeneratorView(store: Store(processor: processor))
        stackNavigator.push(view)
    }

    /// Shows the generator history screen.
    ///
    private func showGeneratorHistory() {
        let processor = GeneratorHistoryProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: GeneratorHistoryState()
        )
        let view = GeneratorHistoryView(store: Store(processor: processor))
        let hostingController = UIHostingController(rootView: view)
        stackNavigator.present(UINavigationController(rootViewController: hostingController))
    }
}
