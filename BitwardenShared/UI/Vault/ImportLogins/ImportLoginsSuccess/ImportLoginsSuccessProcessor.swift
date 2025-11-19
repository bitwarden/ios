import BitwardenKit

// MARK: - ImportLoginsSuccessProcessor

/// The processor used to manage state and handle actions for the import logins success screen.
///
class ImportLoginsSuccessProcessor: StateProcessor<Void, Void, ImportLoginsSuccessEffect> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<ImportLoginsRoute, ImportLoginsEvent>

    // MARK: Initialization

    /// Creates a new `ImportLoginsSuccessProcessor`.
    ///
    /// - Parameter coordinator: The coordinator that handles navigation.
    ///
    init(coordinator: AnyCoordinator<ImportLoginsRoute, ImportLoginsEvent>) {
        self.coordinator = coordinator
        super.init()
    }

    // MARK: Methods

    override func perform(_ effect: ImportLoginsSuccessEffect) async {
        switch effect {
        case .dismiss:
            await coordinator.handleEvent(.completeImportLogins)
        }
    }
}
