import Combine
import SwiftUI

// MARK: - IntroCarouselProcessor

/// The processor used to manage state and handle actions for the intro carousel screen.
///
class IntroCarouselProcessor: StateProcessor<IntroCarouselState, IntroCarouselAction, IntroCarouselEffect> {
    // MARK: Types

    typealias Services = HasConfigService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services required by this processor.
    private let services: Services

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
        services: Services,
        state: IntroCarouselState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: IntroCarouselEffect) async {
        switch effect {
        case .createAccount:
            coordinator.navigate(to: .startRegistration, context: self)
        }
    }

    override func receive(_ action: IntroCarouselAction) {
        switch action {
        case let .currentPageIndexChanged(newValue):
            state.currentPageIndex = newValue
        case .logIn:
            coordinator.navigate(to: .landing)
        }
    }
}

// MARK: - StartRegistrationDelegate

extension IntroCarouselProcessor: StartRegistrationDelegate {
    func didChangeRegion() async {
        // No-op: the carousel doesn't show the region so there's nothing to do here.
    }
}
