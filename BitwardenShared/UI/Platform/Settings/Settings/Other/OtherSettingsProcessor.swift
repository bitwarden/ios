// MARK: - OtherSettingsProcessor

/// The processor used to manage state and handle actions for the `OtherSettingsView`.
///
final class OtherSettingsProcessor: StateProcessor<OtherSettingsState, OtherSettingsAction, OtherSettingsEffect> {
    // MARK: Types

    typealias Services = HasSettingsRepository

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `OtherSettingsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    init(
        coordinator: AnyCoordinator<SettingsRoute>,
        services: Services,
        state: OtherSettingsState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: OtherSettingsEffect) async {
        switch effect {
        case .syncNow:
            await syncVault()
        }
    }

    override func receive(_ action: OtherSettingsAction) {
        switch action {
        case let .toastShown(newValue):
            state.toast = newValue
        case let .toggleAllowSyncOnRefresh(isOn):
            state.isAllowSyncOnRefreshToggleOn = isOn
        case let .toggleConnectToWatch(isOn):
            state.isConnectToWatchToggleOn = isOn
        }
    }

    // MARK: Private

    /// Syncs the user's vault with the API.
    ///
    private func syncVault() async {
        coordinator.showLoadingOverlay(title: Localizations.syncing)
        defer { coordinator.hideLoadingOverlay() }

        do {
            try await services.settingsRepository.fetchSync()
            state.toast = Toast(text: Localizations.syncingComplete)
        } catch {
            coordinator.showAlert(.networkResponseError(error) {
                await self.syncVault()
            })
        }
    }
}
