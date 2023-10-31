import BitwardenSdk
import SwiftUI

// MARK: - VaultMainView

/// The main view of the vault.
private struct VaultMainView: View {
    // MARK: Properties

    /// A flag indicating if the search bar is focused.
    @Environment(\.isSearching) private var isSearching

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, Void>

    var body: some View {
        // A ZStack with hidden children is used here so that opening and closing the
        // search interface does not reset the scroll position for the main vault
        // view, as would happen if we used an `if else` block here.
        //
        // Additionally, we cannot use an `.overlay()` on the main vault view to contain
        // the search interface since VoiceOver still reads the elements below the overlay,
        // which is not ideal.

        ZStack {
            let isSearching = isSearching
                || !store.state.searchText.isEmpty
                || !store.state.searchResults.isEmpty

            emptyVault
                .hidden(isSearching)

            search
                .hidden(!isSearching)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .animation(.default, value: isSearching)
    }

    // MARK: Private Properties

    /// A view that displays the empty vault interface.
    @ViewBuilder private var emptyVault: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Text(Localizations.noItems)
                        .multilineTextAlignment(.center)
                        .font(.styleGuide(.callout))
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                    Button(Localizations.addAnItem) {
                        store.send(.addItemPressed)
                    }
                    .buttonStyle(.tertiary())

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minHeight: reader.size.height)
            }
        }
    }

    /// A view that displays the search interface, including search results, an empty search
    /// interface, and a message indicating that no results were found.
    @ViewBuilder private var search: some View {
        if store.state.searchText.isEmpty || !store.state.searchResults.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.state.searchResults) { item in
                        Button {
                            store.send(.itemPressed(item: item))
                        } label: {
                            vaultItemRow(
                                for: item,
                                isLastInSection: store.state.searchResults.last == item
                            )
                            .background(Asset.Colors.backgroundElevatedTertiary.swiftUIColor)
                        }
                    }
                }
            }
        } else {
            GeometryReader { reader in
                ScrollView {
                    VStack(spacing: 35) {
                        Image(decorative: Asset.Images.magnifyingGlass)
                            .resizable()
                            .frame(width: 74, height: 74)
                            .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                        Text(Localizations.thereAreNoItemsThatMatchTheSearch)
                            .multilineTextAlignment(.center)
                            .font(.styleGuide(.callout))
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    }
                    .frame(maxWidth: .infinity, minHeight: reader.size.height, maxHeight: .infinity)
                }
            }
        }
    }

    // MARK: Private Methods

    /// Creates a row in the list for the provided item.
    ///
    /// - Parameters:
    ///   - item: The `VaultListItem` to use when creating the view.
    ///   - isLastInSection: A flag indicating if this item is the last one in the section.
    ///
    @ViewBuilder
    private func vaultItemRow(for item: VaultListItem, isLastInSection: Bool = false) -> some View {
        VaultListItemRowView(store: store.child(
            state: { _ in
                VaultListItemRowState(
                    item: item,
                    hasDivider: !isLastInSection
                )
            },
            mapAction: { action in
                switch action {
                case .morePressed:
                    return .morePressed(item: item)
                }
            },
            mapEffect: nil
        ))
    }
}

// MARK: - VaultListView

/// A view that allows the user to view a list of the items in their vault.
///
struct VaultListView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, Void>

    var body: some View {
        VaultMainView(store: store)
            .searchable(
                text: store.binding(
                    get: \.searchText,
                    send: VaultListAction.searchTextChanged
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Localizations.search
            )
            .navigationTitle(Localizations.myVault)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        store.send(.profilePressed)
                    } label: {
                        Text(store.state.userInitials)
                            .font(.styleGuide(.caption2))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.purple)
                            .clipShape(Circle())
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addItemPressed)
                    } label: {
                        Label {
                            Text(Localizations.addAnItem)
                        } icon: {
                            Asset.Images.plus.swiftUIImage
                                .resizable()
                                .frame(width: 19, height: 19)
                        }
                    }
                }
            }
    }
}

// MARK: Previews

#if DEBUG
struct VaultListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            userInitials: "AA"
                        )
                    )
                )
            )
        }
        .previewDisplayName("Empty")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            userInitials: "AA",
                            searchText: "Exam",
                            searchResults: [
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
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
                        )
                    )
                )
            )
        }
        .previewDisplayName("1 Search Result")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            userInitials: "AA",
                            searchText: "Exam",
                            searchResults: [
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
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
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    name: "Example 2",
                                    subTitle: "email2@example.com",
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
                                .init(cipherListView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    name: "Example 3",
                                    subTitle: "email3@example.com",
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
                        )
                    )
                )
            )
        }
        .previewDisplayName("3 Search Results")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            userInitials: "AA",
                            searchText: "Exam",
                            searchResults: []
                        )
                    )
                )
            )
        }
        .previewDisplayName("No Search Results")
    }
}
#endif
