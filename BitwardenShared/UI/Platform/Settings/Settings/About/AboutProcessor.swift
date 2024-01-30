// MARK: - AboutProcessor

/// The processor used to manage state and handle actions for the `AboutView`.
///
final class AboutProcessor: StateProcessor<AboutState, AboutAction, Void> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasPasteboardService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `AboutProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: AboutState
    ) {
        self.coordinator = coordinator
        self.services = services

        // Set the initial value of the crash logs toggle.
        var state = state
        state.isSubmitCrashLogsToggleOn = self.services.errorReporter.isEnabled

        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: AboutAction) {
        switch action {
        case .clearAppReviewURL:
            state.appReviewUrl = nil
        case .clearURL:
            state.url = nil
        case .helpCenterTapped:
            state.url = ExternalLinksConstants.helpAndFeedback
        case .rateTheAppTapped:
            coordinator.navigate(to: .alert(.appStoreAlert {
                self.state.appReviewUrl = ExternalLinksConstants.appReview
            }))
        case let .toastShown(newValue):
            state.toast = newValue
        case let .toggleSubmitCrashLogs(isOn):
            state.isSubmitCrashLogsToggleOn = isOn
            services.errorReporter.isEnabled = isOn
        case .versionTapped:
            handleVersionTapped()
        }
    }

    // MARK: - Private Methods

    /// Prepare the text to be copied.
    private func handleVersionTapped() {
        // Copy the copyright text followed by the version info.
        let text = state.copyrightText + "\n\n" + state.version
        services.pasteboardService.copy(text)
        state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.appInfo))
    }
}
