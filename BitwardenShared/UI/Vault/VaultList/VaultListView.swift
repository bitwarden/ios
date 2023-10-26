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
                LazyVStack {
                    ForEach(store.state.searchResults) { item in
                        switch item.itemType {
                        case let .cipher(cipherItem):
                            Button {
                                store.send(.itemPressed(item: cipherItem))
                            } label: {
                                CipherListViewRowView(item: cipherItem)
                            }
                        case .group:
                            EmptyView()
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
                            .font(.styleGuide(.callout))
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    }
                    .frame(maxWidth: .infinity, minHeight: reader.size.height, maxHeight: .infinity)
                }
            }
        }
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

    // MARK: Private Properties

    /// The empty state for this view, displayed when there are no items in the vault.
    @ViewBuilder private var empty: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Text(Localizations.noItems)
                        .multilineTextAlignment(.center)

                    Button(Localizations.addAnItem) {
                        store.send(.addItemPressed)
                    }
                    .buttonStyle(.tertiary())

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minHeight: reader.size.height)
            }
            .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        }
    }
}

// MARK: Previews

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
                            searchResults: []
                        )
                    )
                )
            )
        }
        .previewDisplayName("No Search Results")
    }
}
