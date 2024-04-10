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
            validateFieldsAndExportVault()
        case let .fileFormatTypeChanged(fileFormat):
            state.fileFormat = fileFormat
        case let .filePasswordTextChanged(newValue):
            state.filePasswordText = newValue
            updatePasswordStrength()
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
        let password = state.filePasswordText

        // Show the alert to confirm exporting the vault.
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

    /// Updates state's password strength score based on the user's entered password.
    ///
    private func updatePasswordStrength() {
        guard !state.filePasswordText.isEmpty else {
            state.filePasswordStrengthScore = nil
            return
        }
        Task {
            state.filePasswordStrengthScore = try? await services.authRepository.passwordStrength(
                email: "",
                password: state.filePasswordText
            )
        }
    }

    /// Validates the input fields and if they are valid, shows the alert to confirm the vault export.
    ///
    private func validateFieldsAndExportVault() {
        let isEncryptedExport = state.fileFormat == .jsonEncrypted

        do {
            if isEncryptedExport {
                try EmptyInputValidator(fieldName: Localizations.filePassword)
                    .validate(input: state.filePasswordText)
                try EmptyInputValidator(fieldName: Localizations.confirmFilePassword)
                    .validate(input: state.filePasswordConfirmationText)

                guard state.filePasswordText == state.filePasswordConfirmationText else {
                    coordinator.showAlert(.passwordsDontMatch)
                    return
                }
            }

            try EmptyInputValidator(fieldName: Localizations.masterPassword)
                .validate(input: state.masterPasswordText)

            confirmExportVault()
        } catch let error as InputValidationError {
            coordinator.showAlert(.inputValidationAlert(error: error))
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Validate the password.
    ///
    /// - Returns: `true` if the password is valid.
    ///
    private func validatePassword() async -> Bool {
        do {
            return try await services.authRepository.validatePassword(state.masterPasswordText)
        } catch {
            services.errorReporter.log(error: error)
            return false
        }
    }
}
