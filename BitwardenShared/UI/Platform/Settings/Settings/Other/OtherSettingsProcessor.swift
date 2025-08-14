import BitwardenResources
import Foundation
import WatchConnectivity

// MARK: - OtherSettingsProcessor

/// The processor used to manage state and handle actions for the `OtherSettingsView`.
///
final class OtherSettingsProcessor: StateProcessor<OtherSettingsState, OtherSettingsAction, OtherSettingsEffect> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasSettingsRepository
        & HasSystemDevice
        & HasWatchService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

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
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
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
        case .loadInitialValues:
            await loadInitialValues()
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
            updateAllowSyncOnRefresh(isOn)
        case let .toggleAllowUniversalClipboard(isOn):
            services.settingsRepository.allowUniversalClipboard = isOn
            state.isAllowUniversalClipboardToggleOn = isOn
        case let .toggleConnectToWatch(isOn):
            updateConnectToWatch(isOn)
        case let .toggleSiriAndShortcutsAccessToggleOn(isOn):
            updateSiriAndShortcutsAccess(isOn)
        }
    }

    // MARK: Private

    /// Load the initial values for the toggles on the view.
    private func loadInitialValues() async {
        do {
            state.clearClipboardValue = services.settingsRepository.clearClipboardValue
            state.isAllowUniversalClipboardToggleOn = services.settingsRepository.allowUniversalClipboard
            state.isAllowSyncOnRefreshToggleOn = try await services.settingsRepository.getAllowSyncOnRefresh()
            state.isConnectToWatchToggleOn = try await services.settingsRepository.getConnectToWatch()
            state.isSiriAndShortcutsAccessToggleOn = try await services.settingsRepository.getSiriAndShortcutsAccess()
            state.shouldShowConnectToWatchToggle = services.watchService.isSupported()
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
            state.toast = Toast(title: Localizations.syncingComplete)
        } catch {
            await coordinator.showErrorAlert(error: error) {
                await self.syncVault()
            }
            services.errorReporter.log(error: error)
        }
    }

    /// Update the value of allowing sync on refresh.
    private func updateAllowSyncOnRefresh(_ newValue: Bool) {
        Task {
            do {
                try await services.settingsRepository.updateAllowSyncOnRefresh(newValue)
                state.isAllowSyncOnRefreshToggleOn = newValue
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }

    /// Update the value of the connect to watch setting.
    private func updateConnectToWatch(_ newValue: Bool) {
        Task {
            do {
                try await services.settingsRepository.updateConnectToWatch(newValue)
                state.isConnectToWatchToggleOn = newValue
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }

    /// Update the value of the Siri & Shortcuts access setting.
    private func updateSiriAndShortcutsAccess(_ newValue: Bool) {
        Task {
            do {
                try await services.settingsRepository.updateSiriAndShortcutsAccess(newValue)
                state.isSiriAndShortcutsAccessToggleOn = newValue
            } catch {
                services.errorReporter.log(error: error)
            }
        }
    }
}
