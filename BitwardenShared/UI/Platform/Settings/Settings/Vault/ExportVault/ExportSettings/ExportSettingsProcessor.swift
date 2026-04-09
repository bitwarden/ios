import BitwardenKit

// MARK: - ExportSettingsProcessor

/// The processor used to manage state and handle actions for the `ExportSettingsView`.
///
final class ExportSettingsProcessor: StateProcessor<Void, ExportSettingsAction, Void> {
    // MARK: Properties

    /// The coordinator used to manage navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    // MARK: Initialization

    /// Initializes a new `ExportSettingsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used to manage navigation.
    ///
    init(coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>) {
        self.coordinator = coordinator
        super.init()
    }

    // MARK: Methods

    override func receive(_ action: ExportSettingsAction) {
        switch action {
        case .exportToAppTapped:
            coordinator.navigate(to: .exportVaultToApp)
        case .exportToFileTapped:
            coordinator.navigate(to: .exportVaultToFile)
        }
    }
}
