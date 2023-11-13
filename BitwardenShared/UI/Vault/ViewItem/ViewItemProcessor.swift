import BitwardenSdk

// MARK: - ViewItemProcessor

/// A processor that can process `ViewItemAction`s.
final class ViewItemProcessor: StateProcessor<ViewItemState, ViewItemAction, ViewItemEffect> {
    // MARK: Types

    typealias Services = HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private let coordinator: any Coordinator<VaultRoute>

    /// The ID of the item being viewed.
    private let itemId: String

    /// The services used by this processor.
    private let services: Services

    // MARK: Intialization

    /// Creates a new `ViewItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordiantor: The `Coordinator` for this processor.
    ///   - itemId: The id of the item that is being viewed.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: any Coordinator<VaultRoute>,
        itemId: String,
        services: Services,
        state: ViewItemState
    ) {
        self.coordinator = coordinator
        self.itemId = itemId
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: ViewItemEffect) async {
        switch effect {
        case .appeared:
            await refreshVault()
            for await value in services.vaultRepository.cipherDetailsPublisher(id: itemId) {
                guard let newState = ViewItemState(cipherView: value) else { continue }
                state = newState
            }
        }
    }

    override func receive(_ action: ViewItemAction) {
        switch action {
        case .checkPasswordPressed:
            // TODO: BIT-1130 Check password
            print("check password")
        case let .copyPressed(value):
            // TODO: BIT-1121 Copy value to clipboard
            print("copy: \(value)")
        case .dismissPressed:
            coordinator.navigate(to: .dismiss)
        case .editPressed:
            // TODO: BIT-220 Navigate to the edit route
            print("edit pressed")
        case .morePressed:
            // TODO: BIT-1131 Open item menu
            print("more pressed")
        case .passwordVisibilityPressed:
            switch state.typeState {
            case var .login(loginState):
                loginState.isPasswordVisible.toggle()
                state.typeState = .login(loginState)
            default:
                assertionFailure("Cannot toggle password for non-login item.")
            }
        }
    }

    // MARK: Private Methods

    private func refreshVault() async {
        do {
            try await services.vaultRepository.fetchSync()
        } catch {
            // TODO: BIT-1034 Add an error alert
            print(error)
        }
    }
}
