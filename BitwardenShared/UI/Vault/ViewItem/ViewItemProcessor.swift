import BitwardenSdk

// MARK: - ViewItemProcessor

/// A processor that can process `ViewItemAction`s.
final class ViewItemProcessor: StateProcessor<ViewItemState, ViewItemAction, Void> {
    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private let coordinator: any Coordinator<VaultRoute>

    /// The ID of the item being viewed.
    private let itemId: String

    // MARK: Intialization

    /// Creates a new `ViewItemProcessor`.
    ///
    /// - Parameters:
    ///   - coordiantor: The `Coordinator` for this processor.
    ///   - itemId: The id of the item that is being viewed.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: any Coordinator<VaultRoute>,
        itemId: String,
        state: ViewItemState
    ) {
        self.coordinator = coordinator
        self.itemId = itemId
        super.init(state: state)
    }

    // MARK: Methods

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
}
