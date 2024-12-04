import Combine
import SwiftUI

// MARK: - NewDeviceNoticeProcessor

/// The processor used to manage state and handle actions for the new device notice screen.
///
class NewDeviceNoticeProcessor: StateProcessor<NewDeviceNoticeState, NewDeviceNoticeAction, NewDeviceNoticeEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthEvent>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `NewDeviceNoticeProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AuthRoute, AuthEvent>,
        services: Services,
        state: NewDeviceNoticeState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: NewDeviceNoticeEffect) async {
    }

    override func receive(_ action: NewDeviceNoticeAction) {
    }
}
