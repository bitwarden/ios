import Combine
import SwiftUI

// MARK: - SetUpTwoFactorProcessor

/// The processor used to manage state and handle actions for the new device notice screen.
///
class SetUpTwoFactorProcessor: StateProcessor<SetUpTwoFactorState, SetUpTwoFactorAction, SetUpTwoFactorEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasEnvironmentService
        & HasStateService
        & HasTimeProvider

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<NoTwoFactorRoute, Void>

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
        coordinator: AnyCoordinator<NoTwoFactorRoute, Void>,
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
        case .appeared:
            break
        case .remindMeLaterTapped:
            await handleDismiss()
        }
    }

    override func receive(_ action: SetUpTwoFactorAction) {
        switch action {
        case .clearURL:
            state.url = nil
        case .turnOnTwoFactorTapped:
            coordinator.showAlert(.turnOnTwoFactorLoginAlert {
                self.state.url = self.services.environmentService.setUpTwoFactorURL
            })
        case .changeAccountEmailTapped:
            coordinator.showAlert(.changeEmailAlert {
                self.state.url = self.services.environmentService.changeEmailURL
            })
        }
    }

    // MARK: Private Methods

    private func handleDismiss() async {
        do {
            let currentTime = services.timeProvider.presentTime
            try await services.stateService.setTwoFactorNoticeDisplayState(state: .seen(currentTime))
            coordinator.navigate(to: .dismiss)
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
