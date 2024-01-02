// MARK: - AppearanceProcessor

/// The processor used to manage state and handle actions for the `AppearanceView`.
///
final class AppearanceProcessor: StateProcessor<AppearanceState, AppearanceAction, Void> {
    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    // MARK: Initialization

    /// Initializes a new `AppearanceProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        state: AppearanceState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: AppearanceAction) {
        switch action {
        case .defaultDarkThemeChanged:
            print("languageTapped")
        case .defaultThemeChanged:
            print("languageTapped")
        case .languageTapped:
            print("languageTapped")
        case let .toggleShowWebsiteIcons(isOn):
            state.isShowWebsiteIconsToggleOn = isOn
        }
    }
}
