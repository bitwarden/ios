// MARK: - ExportVaultProcessor

/// The processor used to manage state and handle actions for the `ExportVaultView`.
final class ExportVaultProcessor: StateProcessor<ExportVaultState, ExportVaultAction, ExportVaultEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasSettingsRepository

    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute>

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
        coordinator: AnyCoordinator<SettingsRoute>,
        services: Services
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: ExportVaultState())
    }

    // MARK: Methods

    override func perform(_: ExportVaultEffect) async {}

    override func receive(_ action: ExportVaultAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .fileFormatTypeChanged(fileFormat):
            state.fileFormat = fileFormat
        case let .passwordTextChanged(newValue):
            state.passwordText = newValue
        case let .togglePasswordVisibility(isOn):
            state.isPasswordVisible = isOn
        }
    }
}
