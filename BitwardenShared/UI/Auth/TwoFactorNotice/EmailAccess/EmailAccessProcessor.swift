import Combine
import SwiftUI

// MARK: - EmailAccessProcessor

/// The processor used to manage state and handle actions for the new device notice screen.
///
class EmailAccessProcessor: StateProcessor<EmailAccessState, EmailAccessAction, EmailAccessEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<TwoFactorNoticeRoute, Void>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `EmailAccessProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<TwoFactorNoticeRoute, Void>,
        services: Services,
        state: EmailAccessState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: EmailAccessEffect) async {
        switch effect {
        case .continueTapped:
            await handleContinue()
        }
    }

    override func receive(_ action: EmailAccessAction) {
        switch action {
        case let .canAccessEmailChanged(canAccess):
            state.canAccessEmail = canAccess
        }
    }

    // MARK: Private Methods

    /// Checks the state of the UI when the user taps the continue button
    /// and routes accordingly.
    private func handleContinue() async {
        do {
            if state.canAccessEmail {
                let displayState: TwoFactorNoticeDisplayState
                displayState = state.allowDelay ? .canAccessEmail : .canAccessEmailPermanent
                try await services.stateService.setTwoFactorNoticeDisplayState(state: displayState)
                coordinator.navigate(to: .dismiss)
            } else {
                coordinator.navigate(to: .setUpTwoFactor(allowDelay: state.allowDelay))
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
