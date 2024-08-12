import Combine
import SwiftUI

// MARK: - IntroCarouselProcessor

/// The processor used to manage state and handle actions for the intro carousel screen.
///
class IntroCarouselProcessor: StateProcessor<IntroCarouselState, IntroCarouselAction, Void> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    // MARK: Initialization

    /// Creates a new `IntroCarouselProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        state: IntroCarouselState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: IntroCarouselAction) {
        switch action {
        case .createAccount:
            coordinator.navigate(to: .createAccount)
        case let .currentPageIndexChanged(newValue):
            state.currentPageIndex = newValue
        case .logIn:
            coordinator.navigate(to: .landing)
        }
    }
}
