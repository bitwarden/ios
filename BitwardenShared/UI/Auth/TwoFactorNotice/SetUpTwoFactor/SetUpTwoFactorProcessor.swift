import Combine
import SwiftUI

// MARK: - SetUpTwoFactorProcessor

/// The processor used to manage state and handle actions for the new device notice screen.
///
class SetUpTwoFactorProcessor: StateProcessor<SetUpTwoFactorState, SetUpTwoFactorAction, SetUpTwoFactorEffect> {
    // MARK: Types

    typealias Services = HasEnvironmentService
        & HasErrorReporter
        & HasStateService
        & HasTimeProvider

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<TwoFactorNoticeRoute, Void>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `SetUpTwoFactorProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<TwoFactorNoticeRoute, Void>,
        services: Services,
        state: SetUpTwoFactorState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SetUpTwoFactorEffect) async {
        switch effect {
        case .changeAccountEmailTapped:
            await handleChangeAccountEmail()
        case .remindMeLaterTapped:
            await handleDismiss()
        case .turnOnTwoFactorTapped:
            await handleTurnOnTwoFactor()
        }
    }

    override func receive(_ action: SetUpTwoFactorAction) {
        switch action {
        case .clearURL:
            state.url = nil
        }
    }

    // MARK: Private Methods

    /// Handles when the user taps the Change Account Email button. This will
    /// give the user the ability to go to the website to change their email, and
    /// will in the process nil the last sync time so the next time the app launches
    /// it will be able to sync immediately.
    private func handleChangeAccountEmail() async {
        do {
            try await services.stateService.setLastSyncTime(nil)
            coordinator.showAlert(.changeEmailAlert {
                self.state.url = self.services.environmentService.changeEmailURL
            })
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Saves the current time to disk when the user dismisses the notice.
    private func handleDismiss() async {
        do {
            let currentTime = services.timeProvider.presentTime
            try await services.stateService.setTwoFactorNoticeDisplayState(state: .seen(currentTime))
            coordinator.navigate(to: .dismiss)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Handles when the user taps the Turn On Two-Step button. This will
    /// give the user the ability to go to the website to change their email, and
    /// will in the process nil the last sync time so the next time the app launches
    /// it will be able to sync immediately.
    private func handleTurnOnTwoFactor() async {
        do {
            try await services.stateService.setLastSyncTime(nil)
            coordinator.showAlert(.turnOnTwoFactorLoginAlert {
                self.state.url = self.services.environmentService.setUpTwoFactorURL
            })
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
