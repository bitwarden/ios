// MARK: - OtherSettingsProcessor

/// The processor used to manage state and handle actions for the `OtherSettingsView`.
///
final class OtherSettingsProcessor: StateProcessor<OtherSettingsState, OtherSettingsAction, Void> {
    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    // MARK: Initialization

    /// Initializes a new `OtherSettingsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - state: The initial state of the processor.
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        state: OtherSettingsState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: OtherSettingsAction) {
        switch action {
        case let .toggleAllowSyncOnRefresh(isOn):
            state.isAllowSyncOnRefreshToggleOn = isOn
        case let .toggleConnectToWatch(isOn):
            state.isConnectToWatchToggleOn = isOn
        }
    }
}
