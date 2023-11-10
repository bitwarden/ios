import BitwardenSdk
import OSLog

/// The processor used to manage state and handle actions for the generator history screen.
///
final class GeneratorHistoryProcessor: StateProcessor<
    GeneratorHistoryState,
    GeneratorHistoryAction,
    GeneratorHistoryEffect
> {
    // MARK: Types

    typealias Services = HasGeneratorRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<GeneratorRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `GeneratorHistoryProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<GeneratorRoute>,
        services: Services,
        state: GeneratorHistoryState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: GeneratorHistoryEffect) async {
        switch effect {
        case .appeared:
            for await passwordHistory in services.generatorRepository.passwordHistoryPublisher() {
                state.passwordHistory = passwordHistory
            }
        case .clearList:
            await services.generatorRepository.clearPasswordHistory()
        }
    }

    override func receive(_ action: GeneratorHistoryAction) {
        switch action {
        case .copyPassword:
            // TODO: BIT-1005 Copy password
            break
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }
}
