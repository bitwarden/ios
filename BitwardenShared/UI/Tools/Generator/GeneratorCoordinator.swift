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

    typealias Services = HasGeneratorRepository

    // MARK: Private Properties

    /// A delegate that responds to events in this coordinator.
    private let delegate: GeneratorCoordinatorDelegate?

    // MARK: Properties

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `GeneratorCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: An optional delegate that responds to events in this coordinator.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: GeneratorCoordinatorDelegate?,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: GeneratorRoute, context: AnyObject?) {
        switch route {
        case .cancel:
            delegate?.didCancelGenerator()
        case let .complete(type, value):
            delegate?.didCompleteGenerator(for: type, with: value)
        case let .generator(type):
            showGenerator(for: type)
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
    private func showGenerator(for type: GeneratorType?) {
        let state = GeneratorState(
            generatorType: type ?? .password,
            isDismissButtonVisible: delegate != nil,
            isSelectButtonVisible: delegate != nil,
            isTypeFieldVisible: type == nil
        )
        let processor = GeneratorProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )
        let view = GeneratorView(store: Store(processor: processor))
        stackNavigator.replace(view)
    }
}
