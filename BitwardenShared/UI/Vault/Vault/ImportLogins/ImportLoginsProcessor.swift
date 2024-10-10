// MARK: - ImportLoginsProcessor

/// The processor used to manage state and handle actions for the import logins screen.
///
class ImportLoginsProcessor: StateProcessor<ImportLoginsState, ImportLoginsAction, ImportLoginsEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute, AuthAction>

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
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
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
        case .importLoginsLater:
            showImportLoginsLaterAlert()
        }
    }

    override func receive(_ action: ImportLoginsAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case .getStarted:
            showGetStartAlert()
        }
    }

    // MARK: Private

    /// Shows the alert confirming the user wants to get started on importing logins.
    ///
    private func showGetStartAlert() {
        coordinator.showAlert(.importLoginsComputerAvailable {
            // TODO: PM-11150 Show step 1
        })
    }

    /// Shows the alert confirming the user wants to import logins later.
    ///
    private func showImportLoginsLaterAlert() {
        coordinator.showAlert(.importLoginsLater {
            do {
                try await self.services.stateService.setAccountSetupImportLogins(.setUpLater)
            } catch {
                self.services.errorReporter.log(error: error)
            }
            self.coordinator.navigate(to: .dismiss)
        })
    }
}
