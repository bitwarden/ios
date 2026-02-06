import BitwardenKit

// MARK: - TutorialProcessor

/// The processor used to manage state and handle actions for the tutorial screen.
///
final class TutorialProcessor: StateProcessor<TutorialState, TutorialAction, TutorialEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation, generally a `TutorialCoordinator`.
    private let coordinator: AnyCoordinator<TutorialRoute, TutorialEvent>

    // MARK: Initialization

    /// Creates a new `TutorialProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<TutorialRoute, TutorialEvent>,
        state: TutorialState,
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: TutorialAction) {
        switch action {
        case .continueTapped:
            switch state.page {
            case .intro:
                state.page = .qrScanner
            case .qrScanner:
                state.page = .uniqueCodes
            case .uniqueCodes:
                coordinator.navigate(to: .dismiss)
            }
        case let .pageChanged(page):
            state.page = page
        case .skipTapped:
            coordinator.navigate(to: .dismiss)
        }
    }
}
