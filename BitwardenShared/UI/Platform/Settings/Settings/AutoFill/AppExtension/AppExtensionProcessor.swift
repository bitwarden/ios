// MARK: - AppExtensionProcessorDelegate

/// A delegate of the app extension setup flow that is notified when the user enables the extension.
///
@MainActor
protocol AppExtensionSetupDelegate: AnyObject {
    /// Called when the user dismisses the app extension or the activity view controller during the
    /// extension setup process.
    ///
    /// - Parameter enabled: Whether the extension was successfully invoked and enabled.
    ///
    func didDismissExtensionSetup(enabled: Bool)
}

// MARK: - AppExtensionProcessor

/// The processor used to manage state and handle actions for the `AppExtensionView`.
///
final class AppExtensionProcessor: StateProcessor<AppExtensionState, AppExtensionAction, Void> {
    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    // MARK: Initialization

    /// Initializes a `AppExtensionProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        state: AppExtensionState
    ) {
        self.coordinator = coordinator

        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: AppExtensionAction) {
        switch action {
        case .activateButtonTapped:
            coordinator.navigate(to: .appExtensionSetup, context: self)
        }
    }
}

// MARK: - AppExtensionSetupDelegate

extension AppExtensionProcessor: AppExtensionSetupDelegate {
    func didDismissExtensionSetup(enabled: Bool) {
        guard !state.extensionEnabled else { return }
        state.extensionActivated = true
        state.extensionEnabled = enabled
    }
}
