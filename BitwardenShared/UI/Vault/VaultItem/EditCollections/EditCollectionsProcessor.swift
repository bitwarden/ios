import BitwardenResources

// MARK: - EditCollectionsProcessorDelegate

/// A delegate of `EditCollectionsProcessor` that is notified when the user successfully moves
/// the cipher between collections.
///
@MainActor
protocol EditCollectionsProcessorDelegate: AnyObject {
    /// Called when the user successfully moves the cipher between collections.
    ///
    func didUpdateCipher()
}

// MARK: - EditCollectionsProcessor

/// The processor used to manage state and handle actions for the edit collections screen.
///
class EditCollectionsProcessor: StateProcessor<
    EditCollectionsState,
    EditCollectionsAction,
    EditCollectionsEffect
> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The delegate for the processor that is notified when the user moves the cipher between collections.
    private weak var delegate: EditCollectionsProcessorDelegate?

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `EditCollectionsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate for the processor that is notified when the user moves the
    ///     cipher between collections.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>,
        delegate: EditCollectionsProcessorDelegate?,
        services: Services,
        state: EditCollectionsState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: EditCollectionsEffect) async {
        switch effect {
        case .fetchCipherOptions:
            await fetchCipherOptions()
        case .save:
            await save()
        }
    }

    override func receive(_ action: EditCollectionsAction) {
        switch action {
        case let .collectionToggleChanged(newValue, collectionId):
            state.toggleCollection(newValue: newValue, collectionId: collectionId)
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        }
    }

    // MARK: Private Methods

    /// Fetches any additional data (e.g. collections) needed for moving the cipher.
    ///
    private func fetchCipherOptions() async {
        do {
            state.collections = try await services.vaultRepository.fetchCollections(includeReadOnly: false)
                .filter { $0.organizationId == state.cipher.organizationId }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Saves the updated list of collections to the cipher.
    ///
    private func save() async {
        guard !state.collectionIds.isEmpty else {
            coordinator.showAlert(
                .defaultAlert(
                    title: Localizations.anErrorHasOccurred,
                    message: Localizations.selectOneCollection
                )
            )
            return
        }

        do {
            coordinator.showLoadingOverlay(LoadingOverlayState(title: Localizations.saving))
            defer { coordinator.hideLoadingOverlay() }

            try await services.vaultRepository.updateCipherCollections(state.updatedCipher)

            coordinator.navigate(to: .dismiss(DismissAction {
                self.delegate?.didUpdateCipher()
            }))
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }
}
