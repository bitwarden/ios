// MARK: - ExportVaultProcessor

/// The processor used to manage state and handle actions for the `ExportVaultView`.
final class ExportVaultProcessor: StateProcessor<ExportVaultState, ExportVaultAction, ExportVaultEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasPolicyService
        & HasSettingsRepository

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
            coordinator.navigate(to: .dismiss)
        case .exportVaultTapped:
            confirmExportVault()
        case let .fileFormatTypeChanged(fileFormat):
            state.fileFormat = fileFormat
        case let .passwordTextChanged(newValue):
            state.passwordText = newValue
        case let .togglePasswordVisibility(isOn):
            state.isPasswordVisible = isOn
        }
    }

    // MARK: Private Methods

    /// Show an alert to confirm exporting the vault.
    private func confirmExportVault() {
        let encrypted = (state.fileFormat == .jsonEncrypted)

        // She the alert to confirm exporting the vault.
        coordinator.showAlert(.confirmExportVault(encrypted: encrypted) {
            // Validate the password before exporting the vault.
            guard await self.validatePassword() else {
                return self.coordinator.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword))
            }

            // TODO: BIT-429
            // TODO: BIT-447
            // TODO: BIT-449
        })
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
            return try await services.settingsRepository.validatePassword(state.passwordText)
        } catch {
            services.errorReporter.log(error: error)
            return false
        }
    }
}
