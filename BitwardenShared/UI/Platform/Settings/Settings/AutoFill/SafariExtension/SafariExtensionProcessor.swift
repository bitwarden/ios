import BitwardenKit

// MARK: - SafariExtensionSetupDelegate

/// A delegate of the Safari extension setup flow that is notified about the locally observable outcome.
@MainActor
protocol SafariExtensionSetupDelegate: AnyObject {
    /// Called when the Safari extension setup process finishes with a locally observable result.
    func didDismissSafariExtensionSetup(result: SafariExtensionSetupResult)
}

// MARK: - SafariExtensionSetupResult

/// The observable result of dismissing the Safari extension setup flow.
enum SafariExtensionSetupResult: Equatable {
    /// The setup flow was dismissed without opening the Safari extension activity.
    case dismissed

    /// The Safari extension activity was opened, but iOS did not confirm enablement.
    case setupOpened

    /// The Safari extension activity completed and iOS reported success.
    case enabled
}

// MARK: - SafariExtensionProcessor

/// The processor used to manage state and handle actions for the `SafariExtensionView`.
final class SafariExtensionProcessor: StateProcessor<SafariExtensionState, SafariExtensionAction, Void> {
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        state: SafariExtensionState,
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    override func receive(_ action: SafariExtensionAction) {
        switch action {
        case .activateButtonTapped:
            coordinator.navigate(to: .safariExtensionSetup, context: self)
        }
    }
}

extension SafariExtensionProcessor: SafariExtensionSetupDelegate {
    func didDismissSafariExtensionSetup(result: SafariExtensionSetupResult) {
        guard !state.extensionEnabled else { return }
        switch result {
        case .dismissed:
            break
        case .setupOpened:
            state.setupStatus = .setupOpened
        case .enabled:
            state.setupStatus = .enabled
        }
    }
}
