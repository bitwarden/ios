// MARK: - VaultSettingsProcessor

/// The processor used to manage state and handle actions for the `VaultSettingsView`.
///
final class VaultSettingsProcessor: StateProcessor<VaultSettingsState, VaultSettingsAction, Void> {
    // MARK: Types

    typealias Services = HasEnvironmentService

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

    override func receive(_ action: VaultSettingsAction) {
        switch action {
        case .clearUrl:
            state.url = nil
        case .exportVaultTapped:
            coordinator.navigate(to: .exportVault)
        case .foldersTapped:
            coordinator.navigate(to: .folders)
        case .importItemsTapped:
            coordinator.navigate(to: .alert(.importItemsAlert(importUrl:
                services.environmentService.importItemsURL.absoluteString
            ) {
                self.state.url = self.services.environmentService.importItemsURL
            }))
        }
    }
}
