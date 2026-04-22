import BitwardenKit

// MARK: - SafariExtensionSetupDelegate

/// A delegate of the Safari extension setup flow that is notified when the user enables the extension.
@MainActor
protocol SafariExtensionSetupDelegate: AnyObject {
    /// Called when the user dismisses the Safari extension setup process.
    func didDismissSafariExtensionSetup(enabled: Bool)
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
    func didDismissSafariExtensionSetup(enabled: Bool) {
        guard !state.extensionEnabled else { return }
        state.extensionActivated = true
        state.extensionEnabled = enabled
    }
}
