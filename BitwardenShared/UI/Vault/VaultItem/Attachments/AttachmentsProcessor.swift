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
        case .loadPremiumStatus:
            await loadPremiumStatus()
        case .save:
            await save()
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

    /// Load the user's premium status and display an alert if they do not have access to premium features.
    private func loadPremiumStatus() async {
        do {
            // Fetch the user's premium status.
            state.hasPremium = try await services.vaultRepository.doesActiveAccountHavePremium()

            // If the user does not have access to premium features, show an alert.
            coordinator.showAlert(.defaultAlert(title: Localizations.premiumRequired))
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Presents the file selection alert.
    private func presentFileSelectionAlert() {
        let alert = Alert.fileSelectionOptions { [weak self] route in
            guard let self else { return }
            coordinator.navigate(to: .fileSelection(route), context: self)
        }
        coordinator.showAlert(alert)
    }

    /// Attempt to save the attachment, or show an alert if the user doesn't have access to premium features.
    private func save() async {
        do {
            // Ensure the user has selected a file to save.
            try EmptyInputValidator(fieldName: Localizations.file)
                .validate(input: state.fileName)

            // Display an alert and don't allow the user to continue if
            // they don't have access to premium features.
            guard state.hasPremium else {
                return coordinator.showAlert(.defaultAlert(
                    title: Localizations.anErrorHasOccurred,
                    message: Localizations.premiumRequired
                ))
            }

            // Save the attachment.
            coordinator.showLoadingOverlay(title: Localizations.saving)
            // TODO: BIT-1464
            // TODO: BIT-1465
        } catch let error as InputValidationError {
            coordinator.showAlert(.inputValidationAlert(error: error))
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - FileSelectionDelegate

extension AttachmentsProcessor: FileSelectionDelegate {
    func fileSelectionCompleted(fileName: String, data: Data) {
        state.fileName = fileName
        state.fileData = data
    }
}
