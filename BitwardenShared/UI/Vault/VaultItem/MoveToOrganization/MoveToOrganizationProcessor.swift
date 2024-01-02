// MARK: - MoveToOrganizationProcessor

/// The processor used to manage state and handle actions for the move to organization screen.
///
class MoveToOrganizationProcessor: StateProcessor<
    MoveToOrganizationState,
    MoveToOrganizationAction,
    MoveToOrganizationEffect
> {
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
        state: MoveToOrganizationState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: MoveToOrganizationEffect) async {
        switch effect {
        case .fetchCipherOptions:
            await fetchCipherOptions()
        }
    }

    override func receive(_ action: MoveToOrganizationAction) {
        switch action {
        case let .collectionToggleChanged(newValue, collectionId):
            state.toggleCollection(newValue: newValue, collectionId: collectionId)
        case .dismissPressed:
            coordinator.navigate(to: .dismiss)
        case .moveCipher:
            // TODO: BIT-840 Move cipher
            break
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
}
