import BitwardenResources

// MARK: - AutoFillProcessor

/// The processor used to manage state and handle actions for the auto-fill screen.
///
final class AutoFillProcessor: StateProcessor<AutoFillState, AutoFillAction, AutoFillEffect> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasSettingsRepository
        & HasStateService

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

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
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
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
        case .dismissSetUpAutofillActionCard:
            await dismissSetUpAutofillActionCard()
        case .fetchSettingValues:
            await fetchSettingValues()
        case .streamSettingsBadge:
            await streamSettingsBadge()
        }
    }

    override func receive(_ action: AutoFillAction) {
        switch action {
        case .appExtensionTapped:
            coordinator.navigate(to: .appExtension)
        case let .defaultUriMatchTypeChanged(newValue):
            state.defaultUriMatchType = newValue
            Task {
                await updateDefaultUriMatchType(newValue)
            }
        case .passwordAutoFillTapped:
            coordinator.navigate(to: .passwordAutoFill)
        case .showSetUpAutofill:
            coordinator.navigate(to: .passwordAutoFill)
        case let .toggleCopyTOTPToggle(isOn):
            state.isCopyTOTPToggleOn = isOn
            Task {
                await updateDisableAutoTotpCopy(!isOn)
            }
        }
    }

    // MARK: Private

    /// Dismisses the set up autofill action card by marking the user's vault autofill setup progress complete.
    ///
    private func dismissSetUpAutofillActionCard() async {
        do {
            try await services.stateService.setAccountSetupAutofill(.complete)
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Fetches the initial stored setting values for the view.
    ///
    private func fetchSettingValues() async {
        do {
            state.defaultUriMatchType = await services.settingsRepository.getDefaultUriMatchType()
            state.isCopyTOTPToggleOn = try await !services.settingsRepository.getDisableAutoTotpCopy()
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Streams the state of the badges in the settings tab.
    ///
    private func streamSettingsBadge() async {
        do {
            for await badgeState in try await services.stateService.settingsBadgePublisher().values {
                state.badgeState = badgeState
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Updates the default URI match type value for the user.
    ///
    /// - Parameter defaultUriMatchType: The default URI match type.
    ///
    private func updateDefaultUriMatchType(_ defaultUriMatchType: UriMatchType) async {
        do {
            try await services.settingsRepository.updateDefaultUriMatchType(defaultUriMatchType)
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
