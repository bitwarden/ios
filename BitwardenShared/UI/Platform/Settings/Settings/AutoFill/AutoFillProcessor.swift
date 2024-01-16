// MARK: - AutoFillProcessor

/// The processor used to manage state and handle actions for the auto-fill screen.
///
final class AutoFillProcessor: StateProcessor<AutoFillState, AutoFillAction, AutoFillEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasSettingsRepository

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initializes a new `AutoFillProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        services: Services,
        state: AutoFillState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AutoFillEffect) async {
        switch effect {
        case .fetchSettingValues:
            await fetchSettingValues()
        }
    }

    override func receive(_ action: AutoFillAction) {
        switch action {
        case .appExtensionTapped:
            coordinator.navigate(to: .appExtension)
        case .passwordAutoFillTapped:
            coordinator.navigate(to: .passwordAutoFill)
        case let .toggleCopyTOTPToggle(isOn):
            state.isCopyTOTPToggleOn = isOn
            Task {
                await updateDisableAutoTotpCopy(!isOn)
            }
        }
    }

    // MARK: Private

    /// Fetches the initial stored setting values for the view.
    ///
    private func fetchSettingValues() async {
        do {
            state.isCopyTOTPToggleOn = try await !services.settingsRepository.getDisableAutoTotpCopy()
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Updates the disable auto-copy TOTP setting for the user.
    ///
    /// - Parameter disableAutoTotpCopy: Whether TOTP codes should be auto-copied during autofill.
    ///
    private func updateDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool) async {
        do {
            try await services.settingsRepository.updateDisableAutoTotpCopy(disableAutoTotpCopy)
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }
}
