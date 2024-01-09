import Foundation

// MARK: - AppearanceProcessor

/// The processor used to manage state and handle actions for the `AppearanceView`.
///
final class AppearanceProcessor: StateProcessor<AppearanceState, AppearanceAction, Void> {
    // MARK: Types

    typealias Services = HasStateService

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    /// The services for this processor.
    private var services: Services

    // MARK: Initialization

    /// Initializes a new `AppearanceProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services for this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        services: Services,
        state: AppearanceState
    ) {
        self.coordinator = coordinator
        self.services = services

        // Display the currently selected theme option.
        let themeOption = ThemeOption(self.services.stateService.appTheme)
        var state = state
        state.appTheme = themeOption

        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: AppearanceAction) {
        switch action {
        case .languageTapped:
            print("languageTapped")
        case .themeButtonTapped:
            showThemeOptionsAlert()
        case let .toggleShowWebsiteIcons(isOn):
            state.isShowWebsiteIconsToggleOn = isOn
        }
    }

    // MARK: Private Methods

    /// Show the alert for selecting a theme and save the user's selection.
    private func showThemeOptionsAlert() {
        coordinator.showAlert(.appThemeOptions { [weak self] themeOption in
            // Save the value of the new theme option.
            self?.services.stateService.appTheme = themeOption.value
            self?.coordinator.navigate(to: .updateTheme(theme: themeOption))
            self?.state.appTheme = themeOption
        })
    }
}
