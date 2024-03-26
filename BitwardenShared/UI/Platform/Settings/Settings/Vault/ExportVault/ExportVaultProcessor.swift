import BitwardenSdk
import Foundation

// MARK: - ExportVaultProcessor

/// The processor used to manage state and handle actions for the `ExportVaultView`.
final class ExportVaultProcessor: StateProcessor<ExportVaultState, ExportVaultAction, ExportVaultEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasExportVaultService
        & HasPolicyService

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes a new `ExportVaultProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: ExportVaultState())
    }

    deinit {
        // When the view is dismissed, ensure any temporary files are deleted.
        services.exportVaultService.clearTemporaryFiles()
    }

    // MARK: Methods

    override func perform(_ effect: ExportVaultEffect) async {
        switch effect {
        case .loadData:
            await loadData()
        }
    }

    override func receive(_ action: ExportVaultAction) {
        switch action {
        case .dismiss:
            services.exportVaultService.clearTemporaryFiles()
            coordinator.navigate(to: .dismiss)
        case .exportVaultTapped:
            confirmExportVault()
        case let .fileFormatTypeChanged(fileFormat):
            state.fileFormat = fileFormat
        case let .filePasswordTextChanged(newValue):
            state.filePasswordText = newValue
        case let .filePasswordConfirmationTextChanged(newValue):
            state.filePasswordConfirmationText = newValue
        case let .masterPasswordTextChanged(newValue):
            state.masterPasswordText = newValue
        case let .toggleFilePasswordVisibility(isOn):
            state.isFilePasswordVisible = isOn
        case let .toggleMasterPasswordVisibility(isOn):
            state.isMasterPasswordVisible = isOn
        }
    }

    // MARK: Private Methods

    /// Show an alert to confirm exporting the vault.
    private func confirmExportVault() {
        let encrypted = (state.fileFormat == .jsonEncrypted)
        let format = state.fileFormat
        let password = state.masterPasswordText

        // She the alert to confirm exporting the vault.
        coordinator.showAlert(.confirmExportVault(encrypted: encrypted) {
            // Validate the password before exporting the vault.
            guard await self.validatePassword() else {
                return self.coordinator.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword))
            }

            do {
                try await self.exportVault(format: format, password: password)

                // Clear the user's entered password so that it's required to be entered again for
                // any subsequent exports.
                self.state.masterPasswordText = ""
            } catch {
                self.services.errorReporter.log(error: error)
            }
        })
    }

    /// Export a vault with a given format and trigger a share.
    ///
    /// - Parameters:
    ///    - format: The format of the export file.
    ///    - password: The password used to validate the export.
    ///
    private func exportVault(format: ExportFormatType, password: String) async throws {
        var exportFormat: ExportFileType
        switch format {
        case .csv:
            exportFormat = .csv
        case .json:
            exportFormat = .json
        case .jsonEncrypted:
            exportFormat = .encryptedJson(password: password)
        }

        let fileURL = try await services.exportVaultService.exportVault(format: exportFormat)
        coordinator.navigate(to: .shareExportedVault(fileURL))
    }

    /// Load any initial data for the view.
    ///
    private func loadData() async {
        state.disableIndividualVaultExport = await services.policyService.policyAppliesToUser(
            .disablePersonalVaultExport
        )
    }

    /// Validate the password.
    ///
    /// - Returns: `true` if the password is valid.
    ///
    @MainActor
    private func validatePassword() async -> Bool {
        do {
            return try await services.authRepository.validatePassword(state.masterPasswordText)
        } catch {
            services.errorReporter.log(error: error)
            return false
        }
    }
}
