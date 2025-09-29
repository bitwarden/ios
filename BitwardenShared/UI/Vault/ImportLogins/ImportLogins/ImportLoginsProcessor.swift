import BitwardenKit
import BitwardenResources

// MARK: - ImportLoginsProcessor

/// The processor used to manage state and handle actions for the import logins screen.
///
class ImportLoginsProcessor: StateProcessor<ImportLoginsState, ImportLoginsAction, ImportLoginsEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasSettingsRepository
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<ImportLoginsRoute, ImportLoginsEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `ImportLoginsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<ImportLoginsRoute, ImportLoginsEvent>,
        services: Services,
        state: ImportLoginsState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ImportLoginsEffect) async {
        switch effect {
        case .advanceNextPage:
            await advanceNextPage()
        case .appeared:
            await loadData()
        case .importLoginsLater:
            showImportLoginsLaterAlert()
        }
    }

    override func receive(_ action: ImportLoginsAction) {
        switch action {
        case .advancePreviousPage:
            advancePreviousPage()
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case .getStarted:
            showGetStartAlert()
        }
    }

    // MARK: Private

    /// Advances the view to show the next page of instructions.
    ///
    private func advanceNextPage() async {
        guard let next = state.page.next else {
            // On the last page, hitting next initiates a vault sync.
            await syncVault()
            return
        }
        state.page = next
    }

    /// Advances the view to show the previous page of instructions.
    ///
    private func advancePreviousPage() {
        guard let previous = state.page.previous else { return }
        state.page = previous
    }

    /// Loads the data for the view.
    ///
    private func loadData() async {
        do {
            let account = try await services.stateService.getActiveAccount()
            state.webVaultHost = account.settings.environmentUrls?.webVaultHost ?? Constants.defaultWebVaultHost
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Sets the user's import logins progress to set up later and dismisses the view.
    ///
    private func setImportLoginsLaterAndDismiss() async {
        do {
            try await services.stateService.setAccountSetupImportLogins(.setUpLater)
        } catch {
            services.errorReporter.log(error: error)
        }
        coordinator.navigate(to: .dismiss)
    }

    /// Shows the alert confirming the user wants to get started on importing logins.
    ///
    private func showGetStartAlert() {
        coordinator.showAlert(.importLoginsComputerAvailable {
            await self.advanceNextPage()
        })
    }

    /// Shows an alert informing the user that their vault is empty after importing logins.
    ///
    private func showImportLoginsEmptyAlert() {
        coordinator.showAlert(.importLoginsEmpty {
            await self.setImportLoginsLaterAndDismiss()
        })
    }

    /// Shows the alert confirming the user wants to import logins later.
    ///
    private func showImportLoginsLaterAlert() {
        coordinator.showAlert(.importLoginsLater {
            await self.setImportLoginsLaterAndDismiss()
        })
    }

    /// Syncs the user's vault to fetch any imported logins.
    ///
    private func syncVault() async {
        coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.syncingLogins))
        defer { coordinator.hideLoadingOverlay() }

        do {
            try await services.settingsRepository.fetchSync()

            guard try await !services.vaultRepository.isVaultEmpty() else {
                showImportLoginsEmptyAlert()
                return
            }

            do {
                try await services.stateService.setAccountSetupImportLogins(.complete)
            } catch {
                services.errorReporter.log(error: error)
            }

            coordinator.navigate(to: .importLoginsSuccess)
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }
}
