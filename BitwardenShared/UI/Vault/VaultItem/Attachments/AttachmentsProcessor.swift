import Foundation

// MARK: - MoveToOrganizationProcessor

/// The processor used to manage state and handle actions for `AttachmentsView`.
///
class AttachmentsProcessor: StateProcessor<AttachmentsState, AttachmentsAction, AttachmentsEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultItemRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `MoveToOrganizationProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultItemRoute>,
        services: Services,
        state: AttachmentsState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AttachmentsEffect) async {
        switch effect {
        case .save:
            break
        }
    }

    override func receive(_ action: AttachmentsAction) {
        switch action {
        case .chooseFilePressed:
            presentFileSelectionAlert()
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        }
    }

    // MARK: Private Methods

    /// Presents the file selection alert.
    ///
    private func presentFileSelectionAlert() {
        let alert = Alert.fileSelectionOptions { [weak self] route in
            guard let self else { return }
            coordinator.navigate(to: .fileSelection(route), context: self)
        }
        coordinator.showAlert(alert)
    }
}

// MARK: - FileSelectionDelegate

extension AttachmentsProcessor: FileSelectionDelegate {
    func fileSelectionCompleted(fileName: String, data: Data) {
        state.fileName = fileName
        state.fileData = data
    }
}
