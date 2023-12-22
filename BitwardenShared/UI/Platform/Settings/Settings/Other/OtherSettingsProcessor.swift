import Foundation

// MARK: - OtherSettingsProcessor

/// The processor used to manage state and handle actions for the `OtherSettingsView`.
///
final class OtherSettingsProcessor: StateProcessor<OtherSettingsState, OtherSettingsAction, OtherSettingsEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasSettingsRepository

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

        var state = state
        state.clearClipboardValue = self.services.settingsRepository.clearClipboardValue

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: OtherSettingsEffect) async {
        switch effect {
        case .loadInitialValues:
            await getAllowSyncOnRefresh()
        case .streamLastSyncTime:
            await streamLastSyncTime()
        case .syncNow:
            await syncVault()
        }
    }

    override func receive(_ action: OtherSettingsAction) {
        switch action {
        case let .clearClipboardValueChanged(newValue):
            state.clearClipboardValue = newValue
            services.settingsRepository.clearClipboardValue = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        case let .toggleAllowSyncOnRefresh(isOn):
            state.isAllowSyncOnRefreshToggleOn = isOn
            updateAllowSyncOnRefresh(isOn)
        case let .toggleConnectToWatch(isOn):
            state.isConnectToWatchToggleOn = isOn
        }
    }

    // MARK: Private

    /// Get the value of allowing sync on refresh.
    private func getAllowSyncOnRefresh() async {
        do {
            state.isAllowSyncOnRefreshToggleOn = try await services.settingsRepository.getAllowSyncOnRefresh()
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Gets the last sync time for the user and streams any changes to it.
    ///
    private func streamLastSyncTime() async {
        do {
            for await lastSyncTime in try await services.settingsRepository.lastSyncTimePublisher() {
                state.lastSyncDate = lastSyncTime
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

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
            services.errorReporter.log(error: error)
        }
    }

    /// Update the value of allowing sync on refresh.
    private func updateAllowSyncOnRefresh(_ newValue: Bool) {
        Task {
            do {
                try await services.settingsRepository.updateAllowSyncOnRefresh(newValue)
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }
}
