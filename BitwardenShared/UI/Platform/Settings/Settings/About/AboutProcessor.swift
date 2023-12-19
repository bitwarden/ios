// MARK: - AboutProcessor

/// The processor used to manage state and handle actions for the `AboutView`.
///
final class AboutProcessor: StateProcessor<AboutState, AboutAction, Void> {
    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    // MARK: Initialization

    /// Initializes a new `AboutProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        state: AboutState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: AboutAction) {
        switch action {
        case .helpCenterTapped:
            break
        case .rateTheAppTapped:
            break
        case let .toggleSubmitCrashLogs(isOn):
            state.isSubmitCrashLogsToggleOn = isOn
        case .versionTapped:
            break
        }
    }
}
