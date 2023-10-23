/// The processor used to manage state and handle actions for the generator screen.
///
final class GeneratorProcessor: StateProcessor<GeneratorState, GeneratorAction, Void> {
    // MARK: Types

    typealias Services = HasGeneratorRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<GeneratorRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `GeneratorProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<GeneratorRoute>,
        services: Services,
        state: GeneratorState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: GeneratorAction) {}
}
