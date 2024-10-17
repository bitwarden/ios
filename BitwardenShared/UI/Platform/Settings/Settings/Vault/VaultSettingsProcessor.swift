// MARK: - VaultSettingsProcessor

/// The processor used to manage state and handle actions for the `VaultSettingsView`.
///
final class VaultSettingsProcessor: StateProcessor<VaultSettingsState, VaultSettingsAction, VaultSettingsEffect> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasEnvironmentService
        & HasErrorReporter
        & HasStateService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `VaultSettingsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: VaultSettingsState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultSettingsEffect) async {
        switch effect {
        case .dismissImportLoginsActionCard:
            await dismissImportLoginsActionCard()
        case .streamSettingsBadge:
            await streamSettingsBadge()
        }
    }

    override func receive(_ action: VaultSettingsAction) {
        switch action {
        case .clearUrl:
            state.url = nil
        case .exportVaultTapped:
            coordinator.navigate(to: .exportVault)
        case .foldersTapped:
            coordinator.navigate(to: .folders)
        case .importItemsTapped:
            coordinator.showAlert(.importItemsAlert(importUrl:
                services.environmentService.importItemsURL.absoluteString
            ) {
                self.state.url = self.services.environmentService.importItemsURL
            })
        case .showImportLogins:
            // TODO: PM-13467 Navigate to import logins
            // coordinator.navigate(to: .importLogins)
            break
        }
    }

    // MARK: Private

    /// Dismisses the import logins action card by marking the user's import logins progress complete.
    ///
    private func dismissImportLoginsActionCard() async {
        do {
            try await services.stateService.setAccountSetupImportLogins(.complete)
        } catch {
            services.errorReporter.log(error: error)
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
        }
    }

    /// Streams the state of the badges in the settings tab.
    ///
    private func streamSettingsBadge() async {
        guard await services.configService.getFeatureFlag(.importLoginsFlow) else { return }
        do {
            for await badgeState in try await services.stateService.settingsBadgePublisher().values {
                state.badgeState = badgeState
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}
