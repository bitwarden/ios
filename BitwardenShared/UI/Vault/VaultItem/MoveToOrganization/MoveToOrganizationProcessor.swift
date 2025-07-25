import BitwardenResources
import BitwardenSdk

// MARK: - MoveToOrganizationProcessorDelegate

/// A delegate of `MoveToOrganizationProcessor` that is notified when the user successfully moves
/// the cipher to an organization.
///
@MainActor
protocol MoveToOrganizationProcessorDelegate: AnyObject {
    /// Called when the user successfully moves the cipher to an organization.
    ///
    func didMoveCipher(_ cipher: CipherView, to organization: CipherOwner)
}

// MARK: - MoveToOrganizationProcessor

/// The processor used to manage state and handle actions for the move to organization screen.
///
class MoveToOrganizationProcessor: StateProcessor<
    MoveToOrganizationState,
    MoveToOrganizationAction,
    MoveToOrganizationEffect
> {
    // MARK: Types

    typealias Services = HasConfigService
        & HasErrorReporter
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultItemRoute, VaultItemEvent>

    /// The delegate for the processor that is notified when the user moves the cipher to an organization.
    private weak var delegate: MoveToOrganizationProcessorDelegate?

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
        delegate: MoveToOrganizationProcessorDelegate?,
        services: Services,
        state: MoveToOrganizationState
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: MoveToOrganizationEffect) async {
        switch effect {
        case .fetchCipherOptions:
            await fetchCipherOptions()
        case .moveCipher:
            await moveCipher()
        }
    }

    override func receive(_ action: MoveToOrganizationAction) {
        switch action {
        case let .collectionToggleChanged(newValue, collectionId):
            state.toggleCollection(newValue: newValue, collectionId: collectionId)
        case .dismissPressed:
            coordinator.navigate(to: .dismiss())
        case let .ownerChanged(owner):
            state.owner = owner
        }
    }

    // MARK: Private Methods

    /// Fetches any additional data (e.g. organizations and collections) needed for moving the cipher.
    private func fetchCipherOptions() async {
        do {
            state.collections = try await services.vaultRepository.fetchCollections(includeReadOnly: false)
            state.ownershipOptions = try await services.vaultRepository
                .fetchCipherOwnershipOptions(includePersonal: false)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Performs the API request to move the cipher to the organization.
    ///
    private func moveCipher() async {
        guard !state.collectionIds.isEmpty,
              let owner = state.owner,
              let organizationId = state.organizationId else {
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

            try await services.vaultRepository.shareCipher(
                state.cipher,
                newOrganizationId: organizationId,
                newCollectionIds: state.collectionIds
            )

            coordinator.navigate(to: .dismiss(DismissAction {
                self.delegate?.didMoveCipher(self.state.cipher, to: owner)
            }))
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }
}
