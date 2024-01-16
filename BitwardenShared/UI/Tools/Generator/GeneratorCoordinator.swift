import SwiftUI

// MARK: - GeneratorCoordinatorDelegate

/// An object that is signaled when specific circumstances in the generator flow have been
/// encountered.
///
@MainActor
protocol GeneratorCoordinatorDelegate: AnyObject {
    /// Called when the generator flow has been completed.
    ///
    /// - Parameters:
    ///   - type: The type that was generated.
    ///   - value: The value that was generated.
    ///
    func didCompleteGenerator(for type: GeneratorType, with value: String)

    /// Called when the generator flow has been canceled.
    ///
    func didCancelGenerator()
}

// MARK: - GeneratorCoordinator

/// A coordinator that manages navigation in the generator tab.
///
final class GeneratorCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = PasswordHistoryModule

    typealias Services = HasErrorReporter
        & HasGeneratorRepository
        & HasPasteboardService

    // MARK: Private Properties

    /// A delegate that responds to events in this coordinator.
    private weak var delegate: GeneratorCoordinatorDelegate?

    /// The module used by this coordinator to create child coordinators.
    private let module: Module

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `GeneratorCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: An optional delegate that responds to events in this coordinator.
    ///   - module: The module used by this coordinator to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: GeneratorCoordinatorDelegate?,
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

    func navigate(to route: GeneratorRoute, context _: AnyObject?) {
        switch route {
        case .cancel:
            delegate?.didCancelGenerator()
        case let .complete(type, value):
            delegate?.didCompleteGenerator(for: type, with: value)
        case .dismiss:
            stackNavigator.dismiss()
        case let .generator(type, emailWebsite):
            showGenerator(for: type, emailWebsite: emailWebsite)
        case .generatorHistory:
            showGeneratorHistory()
        }
    }

    func start() {
        navigate(to: .generator())
    }

    // MARK: Private Methods

    /// Shows the generator screen.
    ///
    /// - Parameter type: The type to initialize this generator screen with. If a value is provided,
    ///   then the type field in the generator screen will be hidden, to eliminate the ability to
    ///   switch between the various types.
    ///
    private func showGenerator(for type: GeneratorType?, emailWebsite: String?) {
        let state = GeneratorState(
            generatorType: type ?? .password,
            presentationMode: type == nil ? .tab : .inPlace,
            usernameState: GeneratorState.UsernameState(emailWebsite: emailWebsite)
        )
        let processor = GeneratorProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )
        let view = GeneratorView(store: Store(processor: processor))
        stackNavigator.replace(view)
    }

    /// Shows the generator password history screen.
    ///
    private func showGeneratorHistory() {
        let navigationController = UINavigationController()
        let coordinator = module.makePasswordHistoryCoordinator(stackNavigator: navigationController)
        coordinator.start()
        coordinator.navigate(to: .passwordHistoryList(.generator))

        stackNavigator.present(navigationController)
    }
}
