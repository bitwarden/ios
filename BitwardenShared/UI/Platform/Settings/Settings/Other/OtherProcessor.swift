// MARK: - OtherProcessor

/// The processor used to manage state and handle actions for the `OtherView`.
///
final class OtherProcessor: StateProcessor<OtherState, OtherAction, Void> {
    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    // MARK: Initialization

    /// Initializes a new `OtherProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - state: The initial state of the processor.
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        state: OtherState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: OtherAction) {
        switch action {
        case let .toggleAllowSyncOnRefresh(isOn):
            state.isAllowSyncOnRefreshToggleOn = isOn
        case let .toggleConnectToWatch(isOn):
            state.isConnectToWatchToggleOn = isOn
        }
    }
}
