import BitwardenKit
import BitwardenResources
@preconcurrency import BitwardenSdk
import Foundation

// MARK: - MoveToOrganizationProcessor

/// The processor used to manage state and handle actions for `AttachmentsView`.
///
class AttachmentsProcessor: StateProcessor<AttachmentsState, AttachmentsAction, AttachmentsEffect> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

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
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
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
        case let .deletePressed(attachment):
            confirmDeleteAttachment(attachment)
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        case let .toastShown(toast):
            state.toast = toast
        }
    }

    // MARK: Private Methods

    /// Confirm that the user wants to delete the attachment then delete it.
    private func confirmDeleteAttachment(_ attachment: AttachmentView) {
        coordinator.showAlert(.confirmDeleteAttachment {
            await self.deleteAttachment(attachment)
        })
    }

    /// Delete the attachment.
    private func deleteAttachment(_ attachment: AttachmentView) async {
        defer { coordinator.hideLoadingOverlay() }
        do {
            guard let attachmentId = attachment.id, let cipherId = state.cipher?.id else {
                throw CipherAPIServiceError.updateMissingId
            }

            // Delete the attachment.
            coordinator.showLoadingOverlay(title: Localizations.deleting)
            let updatedCipher = try await services.vaultRepository.deleteAttachment(
                withId: attachmentId,
                cipherId: cipherId
            )

            // Update the view and display the toast.
            state.cipher = updatedCipher
            state.toast = Toast(title: Localizations.attachmentDeleted)
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Load the user's premium status and display an alert if they do not have access to premium features.
    private func loadPremiumStatus() async {
        // Fetch the user's premium status.
        state.hasPremium = await services.vaultRepository.doesActiveAccountHavePremium()

        // If the user does not have access to premium features, show an alert.
        if !state.hasPremium {
            coordinator.showAlert(.defaultAlert(title: Localizations.premiumRequired))
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
        defer { coordinator.hideLoadingOverlay() }
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

            // Display an alert if the attachment is too large.
            guard let fileSize = state.fileData?.count, fileSize < Constants.maxFileSize else {
                return coordinator.showAlert(.defaultAlert(
                    title: Localizations.anErrorHasOccurred,
                    message: Localizations.maxFileSize
                ))
            }

            // Save the attachment.
            guard let cipherView = state.cipher, let data = state.fileData, let name = state.fileName else { return }
            coordinator.showLoadingOverlay(title: Localizations.saving)
            let updatedCipherView = try await services.vaultRepository.saveAttachment(
                cipherView: cipherView,
                fileData: data,
                fileName: name
            )

            // Update the view, reset the inputs, and display the toast.
            state.cipher = updatedCipherView
            state.fileName = nil
            state.fileData = nil
            state.toast = Toast(title: Localizations.attachementAdded)
        } catch let error as InputValidationError {
            coordinator.showAlert(.inputValidationAlert(error: error))
        } catch {
            await coordinator.showErrorAlert(error: error)
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
