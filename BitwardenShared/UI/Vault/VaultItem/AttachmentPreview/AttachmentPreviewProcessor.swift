import BitwardenKit
import Foundation

// MARK: - AttachmentPreviewProcessor

/// The processor used to manage state and handle actions for `AttachmentPreviewView`.
///
class AttachmentPreviewProcessor: StateProcessor<
    AttachmentPreviewState,
    AttachmentPreviewAction,
    AttachmentPreviewEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `AttachmentPreviewProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
        services: Services,
        state: AttachmentPreviewState,
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    deinit {
        // When the preview and anything presented on top of it (e.g. the save file picker) are
        // dismissed, ensure any temporary files are deleted.
        services.vaultRepository.clearTemporaryDownloads()
    }

    // MARK: Methods

    override func perform(_ effect: AttachmentPreviewEffect) async {
        switch effect {
        case .downloadPressed:
            coordinator.navigate(to: .saveFile(temporaryUrl: state.temporaryUrl))
        }
    }

    override func receive(_ action: AttachmentPreviewAction) {
        switch action {
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }
}
