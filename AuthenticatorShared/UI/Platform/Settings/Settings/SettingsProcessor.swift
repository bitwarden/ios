import OSLog

// MARK: - SettingsProcessor

/// The processor used to manage state and handle actions for the settings screen.
///
final class SettingsProcessor: StateProcessor<SettingsState, SettingsAction, SettingsEffect> {
    // MARK: Types

    typealias Services = HasAppSettingsStore
        & HasApplication
        & HasAuthenticatorItemRepository
        & HasBiometricsRepository
        & HasConfigService
        & HasErrorReporter
        & HasExportItemsService
        & HasPasteboardService
        & HasStateService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services for this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `SettingsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services for this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: SettingsState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SettingsEffect) async {
        switch effect {
        case .loadData:
            await loadData()
        case let .sessionTimeoutValueChanged(timeoutValue):
            guard case .available = state.biometricUnlockStatus else { return }

            if case .available(_, false, _) = state.biometricUnlockStatus {
                await setBiometricAuth(true)
            }

            state.sessionTimeoutValue = timeoutValue
            services.appSettingsStore.setVaultTimeout(
                minutes: timeoutValue.rawValue,
                userId: services.appSettingsStore.localUserId
            )
        case let .toggleUnlockWithBiometrics(isOn):
            await setBiometricAuth(isOn)
        }
    }

    override func receive(_ action: SettingsAction) {
        switch action {
        case let .appThemeChanged(appTheme):
            state.appTheme = appTheme
            Task {
                await services.stateService.setAppTheme(appTheme)
            }
        case .backupTapped:
            coordinator.showAlert(.backupInformation {
                self.state.url = ExternalLinksConstants.backupInformation
            })
        case .clearURL:
            state.url = nil
        case let .defaultSaveChanged(option):
            state.defaultSaveOption = option
            services.appSettingsStore.defaultSaveOption = option
        case .exportItemsTapped:
            coordinator.navigate(to: .exportItems)
        case .helpCenterTapped:
            state.url = ExternalLinksConstants.helpAndFeedback
        case .importItemsTapped:
            coordinator.navigate(to: .importItems)
        case .languageTapped:
            coordinator.navigate(to: .selectLanguage(currentLanguage: state.currentLanguage), context: self)
        case .privacyPolicyTapped:
            coordinator.showAlert(.privacyPolicyAlert {
                self.state.url = ExternalLinksConstants.privacyPolicy
            })
        case .syncWithBitwardenAppTapped:
            if services.application?.canOpenURL(ExternalLinksConstants.passwordManagerScheme) ?? false {
                state.url = ExternalLinksConstants.passwordManagerSettings
            } else {
                state.url = ExternalLinksConstants.passwordManagerLink
            }
        case let .toastShown(newValue):
            state.toast = newValue
        case .tutorialTapped:
            coordinator.navigate(to: .tutorial)
        case .versionTapped:
            handleVersionTapped()
        }
    }

    // MARK: - Private Methods

    /// Prepare the text to be copied.
    private func handleVersionTapped() {
        // Copy the copyright text followed by the version info.
        let text = "Bitwarden Authenticator\n\n" + state.copyrightText + "\n\n" + state.version
        services.pasteboardService.copy(text)
        state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.appInfo))
    }

    /// Loads the state of the user's biometric unlock preferences.
    ///
    /// - Returns: The `BiometricsUnlockStatus` for the user.
    ///
    private func loadBiometricUnlockPreference() async -> BiometricsUnlockStatus {
        do {
            let biometricsStatus = try await services.biometricsRepository.getBiometricUnlockStatus()
            return biometricsStatus
        } catch {
            Logger.application.debug("Error loading biometric preferences: \(error)")
            return .notAvailable
        }
    }

    /// Load any initial data for the view.
    private func loadData() async {
        state.currentLanguage = services.stateService.appLanguage
        state.appTheme = await services.stateService.getAppTheme()
        state.biometricUnlockStatus = await loadBiometricUnlockPreference()
        state.sessionTimeoutValue = loadTimeoutValue(biometricsEnabled: state.biometricUnlockStatus.isEnabled)
        state.shouldShowSyncButton = await services.configService.getFeatureFlag(.enablePasswordManagerSync)
        if state.shouldShowSyncButton {
            state.shouldShowDefaultSaveOption = await services.authenticatorItemRepository.isPasswordManagerSyncActive()
            state.defaultSaveOption = services.appSettingsStore.defaultSaveOption
        }
    }

    /// Load the Session Timeout Value.
    ///
    /// - Parameter biometricsEnabled: The current state of biometrics. Used to determine the default and
    ///     if there should be a value.
    /// - Returns: The SessionTimeoutValue to set into the state.
    ///
    private func loadTimeoutValue(biometricsEnabled: Bool) -> SessionTimeoutValue {
        guard biometricsEnabled else { return .never }

        let accountId = services.appSettingsStore.localUserId
        if let timeout = services.appSettingsStore.vaultTimeout(userId: accountId) {
            return SessionTimeoutValue(rawValue: timeout)
        } else {
            return .onAppRestart
        }
    }

    /// Sets the user's biometric auth
    ///
    /// - Parameter enabled: Whether or not the the user wants biometric auth enabled.
    ///
    private func setBiometricAuth(_ enabled: Bool) async {
        do {
            try await services.biometricsRepository.setBiometricUnlockKey(authKey: enabled ? "key" : nil)
            state.biometricUnlockStatus = try await services.biometricsRepository.getBiometricUnlockStatus()
            // Set biometric integrity if needed.
            if case .available(_, true, false) = state.biometricUnlockStatus {
                try await services.biometricsRepository.configureBiometricIntegrity()
                state.biometricUnlockStatus = try await services.biometricsRepository.getBiometricUnlockStatus()
            }

            if enabled {
                state.sessionTimeoutValue = .onAppRestart
                services.appSettingsStore.setVaultTimeout(minutes: state.sessionTimeoutValue.rawValue,
                                                          userId: services.appSettingsStore.localUserId)
            } else {
                state.sessionTimeoutValue = .never
                services.appSettingsStore.setVaultTimeout(minutes: state.sessionTimeoutValue.rawValue,
                                                          userId: services.appSettingsStore.localUserId)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - SelectLanguageDelegate

extension SettingsProcessor: SelectLanguageDelegate {
    /// Update the language selection.
    func languageSelected(_ languageOption: LanguageOption) {
        state.currentLanguage = languageOption
    }
}
