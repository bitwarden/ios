import Foundation

// MARK: - AppearanceProcessor

/// The processor used to manage state and handle actions for the `AppearanceView`.
///
final class AppearanceProcessor: StateProcessor<AppearanceState, AppearanceAction, AppearanceEffect> {
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

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AppearanceEffect) async {
        switch effect {
        case .loadData:
            state.currentLanguage = services.stateService.appLanguage
            state.appTheme = await services.stateService.getAppTheme()
            state.isShowWebsiteIconsToggleOn = await services.stateService.getShowWebIcons()
        }
    }

    override func receive(_ action: AppearanceAction) {
        switch action {
        case let .appThemeChanged(appTheme):
            state.appTheme = appTheme
            Task {
                await services.stateService.setAppTheme(appTheme)
            }
        case .languageTapped:
            coordinator.navigate(to: .selectLanguage(currentLanguage: state.currentLanguage), context: self)
        case let .toggleShowWebsiteIcons(isOn):
            state.isShowWebsiteIconsToggleOn = isOn
            Task {
                await services.stateService.setShowWebIcons(isOn)
            }
        }
    }
}

// MARK: - SelectLanguageDelegate

extension AppearanceProcessor: SelectLanguageDelegate {
    /// Update the language selection.
    func languageSelected(_ languageOption: LanguageOption) {
        state.currentLanguage = languageOption
    }
}
