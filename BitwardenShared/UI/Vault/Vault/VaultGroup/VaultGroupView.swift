import SwiftUI

// MARK: - VaultGroupView

/// A view that displays the items in a single vault group.
struct VaultGroupView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The GroupSearchDelegate used to bridge UIKit to SwiftUI
    var searchHandler: VaultGroupSearchHandler?

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultGroupState, VaultGroupAction, VaultGroupEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        content
            .searchable(
                text: store.binding(
                    get: \.searchText,
                    send: VaultGroupAction.searchTextChanged
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Localizations.search
            )
            .navigationTitle(store.state.group.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .background(Asset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
            .toolbar {
                addToolbarItem(hidden: !store.state.showAddToolbarItem) {
                    store.send(.addItemPressed)
                }
            }
            .task {
                await store.perform(.appeared)
            }
            .task {
                await store.perform(.streamOrganizations)
            }
            .task {
                await store.perform(.streamShowWebIcons)
            }
            .toast(store.binding(
                get: \.toast,
                send: VaultGroupAction.toastShown
            ))
    }

    // MARK: Private

    @ViewBuilder private var content: some View {
        searchOrGroup
            .onChange(of: store.state.url) { newValue in
                guard let url = newValue else { return }
                openURL(url)
                store.send(.clearURL)
            }
            .task(id: store.state.searchText) {
                await store.perform(.search(store.state.searchText))
            }
            .task(id: store.state.searchVaultFilterType) {
                await store.perform(.search(store.state.searchText))
            }
            .animation(.default, value: store.state.isSearching)
    }

    /// A view that displays an empty state for this vault group.
    @ViewBuilder private var emptyView: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()

                    Text(store.state.noItemsString)
                        .multilineTextAlignment(.center)
                        .styleGuide(.callout)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                    if store.state.showAddItemButton {
                        Button(Localizations.addAnItem) {
                            store.send(.addItemPressed)
                        }
                        .buttonStyle(.tertiary())
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minWidth: reader.size.width, minHeight: reader.size.height)
            }
        }
    }

    /// A view that displays either the group or empty interface.
    @ViewBuilder private var groupItems: some View {
        LoadingView(state: store.state.loadingState) { items in
            if items.isEmpty {
                emptyView
            } else {
                groupView(with: items)
            }
        }
    }

    /// A view that displays the search interface, including search results, an empty search
    /// interface, and a message indicating that no results were found.
    ///
    @ViewBuilder private var searchContent: some View {
        if store.state.searchText.isEmpty || !store.state.searchResults.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0) {
                    searchVaultFilterRow

                    ForEach(store.state.searchResults) { item in
                        Button {
                            store.send(.itemPressed(item))
                        } label: {
                            vaultItemRow(
                                for: item,
                                isLastInSection: store.state.searchResults.last == item
                            )
                            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
                        }
                    }
                }
            }
        } else {
            SearchNoResultsView {
                searchVaultFilterRow
            }
        }
    }

    /// The group content or search view.
    ///
    ///  If `store.state.isSearching` is `true`:  The view shows the `searchContentView`,
    ///     else: The view shows the `groupItemsView`.
    ///
    @ViewBuilder private var searchOrGroup: some View {
        if store.state.isSearching {
            searchContent
        } else {
            groupItems
        }
    }

    /// Displays the vault filter for search row if the user is a member of any org.
    ///
    private var searchVaultFilterRow: some View {
        SearchVaultFilterRowView(
            hasDivider: true, store: store.child(
                state: \.vaultFilterState,
                mapAction: { action in
                    switch action {
                    case let .searchVaultFilterChanged(type):
                        return .searchVaultFilterChanged(type)
                    }
                },
                mapEffect: nil
            )
        )
    }

    // MARK: Private Methods

    /// A view that displays a list of the sections within this vault group.
    ///
    @ViewBuilder
    private func groupView(with sections: [VaultListSection]) -> some View {
        ScrollView {
            VStack(spacing: 20.0) {
                ForEach(sections) { section in
                    VaultListSectionView(section: section) { item in
                        Button {
                            store.send(.itemPressed(item))
                        } label: {
                            vaultItemRow(for: item, isLastInSection: section.items.last == item)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    /// Creates a row in the list for the provided item.
    ///
    /// - Parameters:
    ///   - item: The `VaultListItem` to use when creating the view.
    ///   - isLastInSection: A flag indicating if this item is the last one in the section.
    ///
    @ViewBuilder
    private func vaultItemRow(for item: VaultListItem, isLastInSection: Bool = false) -> some View {
        VaultListItemRowView(
            store: store.child(
                state: { state in
                    VaultListItemRowState(
                        iconBaseURL: state.iconBaseURL,
                        item: item,
                        hasDivider: !isLastInSection,
                        showWebIcons: state.showWebIcons
                    )
                },
                mapAction: { action in
                    switch action {
                    case let .copyTOTPCode(code):
                        return .copyTOTPCode(code)
                    }
                },
                mapEffect: { effect in
                    switch effect {
                    case .morePressed:
                        return .morePressed(item)
                    }
                }
            ),
            timeProvider: timeProvider
        )
    }
}

// MARK: Previews

#if DEBUG
#Preview("Loading") {
    NavigationView {
        VaultGroupView(
            store: Store(
                processor: StateProcessor(
                    state: VaultGroupState(
                        loadingState: .loading(nil),
                        searchVaultFilterType: .allVaults,
                        vaultFilterType: .allVaults
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}

#Preview("Empty") {
    NavigationView {
        VaultGroupView(
            store: Store(
                processor: StateProcessor(
                    state: VaultGroupState(
                        loadingState: .data([]),
                        searchVaultFilterType: .allVaults,
                        vaultFilterType: .allVaults
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}

#Preview("Logins") {
    NavigationView {
        VaultGroupView(
            store: Store(
                processor: StateProcessor(
                    state: VaultGroupState(
                        group: .login,
                        loadingState: .data(
                            [
                                .init(
                                    id: "Items",
                                    items: [
                                        .init(cipherView: .fixture(
                                            id: "1",
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example"
                                        ))!,
                                        .init(cipherView: .fixture(
                                            id: "2",
                                            login: .fixture(username: "email2@example.com"),
                                            name: "Example 2"
                                        ))!,
                                    ],
                                    name: "Items"
                                ),
                            ]
                        ),
                        searchVaultFilterType: .allVaults,
                        vaultFilterType: .allVaults
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}
#endif
