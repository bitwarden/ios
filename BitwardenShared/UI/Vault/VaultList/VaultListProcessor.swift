import Foundation

// MARK: - VaultListProcessor

/// The processor used to manage state and handle actions for the vault list screen.
///
final class VaultListProcessor: StateProcessor<VaultListState, VaultListAction, Void> {
    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute>

    // MARK: Initialization

    /// Creates a new `VaultListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute>,
        state: VaultListState
    ) {
        self.coordinator = coordinator
        var state = state
        state.userInitials = "NA"
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: VaultListAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem)
        case .itemPressed:
            coordinator.navigate(to: .viewItem)
        case .morePressed:
            // TODO: BIT-0 Show item actions
            break
        case .profilePressed:
            // TODO: BIT-124 Switch account
            break
        case let .searchTextChanged(newValue):
            state.searchText = newValue
            state.searchResults = searchVault(for: newValue)
        }
    }

    // MARK: - Private Methods

    /// Searches the vault using the provided string, and returns any matching results.
    ///
    /// - Parameter searchText: The string to use when searching the vault.
    /// - Returns: An array of `VaultListItem`s. If no results can be found, an empty array will be returned.
    ///
    private func searchVault(for searchText: String) -> [VaultListItem] {
        // TODO: BIT-628 Actually search the vault for the provided string.
        if "example".contains(searchText.lowercased()) {
            return [
                VaultListItem(cipherListView: .init(
                    id: "1",
                    organizationId: nil,
                    folderId: nil,
                    collectionIds: [],
                    name: "Example",
                    subTitle: "email@example.com",
                    type: .login,
                    favorite: true,
                    reprompt: .none,
                    edit: false,
                    viewPassword: true,
                    attachments: 0,
                    creationDate: Date(),
                    deletedDate: nil,
                    revisionDate: Date()
                ))!,
            ]
        } else {
            return []
        }
    }
}
