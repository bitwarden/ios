// swiftlint:disable file_length

import SwiftUI

// MARK: - SearchableItemListView

/// A view that displays the items in a single vault group.
private struct SearchableItemListView: View {
    // MARK: Properties

    /// A flag indicating if the search bar is focused.
    @Environment(\.isSearching) private var isSearching

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<ItemListState, ItemListAction, ItemListEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

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

            content
                .hidden(isSearching)

            search
                .hidden(!isSearching)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .toast(store.binding(
            get: \.toast,
            send: ItemListAction.toastShown
        ))
        .onChange(of: isSearching) { newValue in
            store.send(.searchStateChanged(isSearching: newValue))
        }
        .toast(store.binding(
            get: \.toast,
            send: ItemListAction.toastShown
        ))
        .animation(.default, value: isSearching)
        .toast(store.binding(
            get: \.toast,
            send: ItemListAction.toastShown
        ))
    }

    // MARK: Private

    @ViewBuilder private var content: some View {
        LoadingView(state: store.state.loadingState) { items in
            if items.isEmpty {
                emptyView
            } else {
                groupView(with: items)
            }
        }
    }

    /// A view that displays an empty state for this vault group.
    @ViewBuilder private var emptyView: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 16) {
                    Spacer()

                    Image(decorative: Asset.Images.emptyVault)

                    Text(Localizations.noCodes)
                        .multilineTextAlignment(.center)
                        .styleGuide(.headline)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                    Text(Localizations.addANewCodeToSecure)
                        .multilineTextAlignment(.center)
                        .styleGuide(.callout)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                    if store.state.showAddItemButton {
                        AsyncButton(Localizations.addCode) {
                            await store.perform(.addItemPressed)
                        }
                        .buttonStyle(.primary())
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(minWidth: reader.size.width, minHeight: reader.size.height)
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
                            store.send(.itemPressed(item))
                        } label: {
                            vaultItemRow(
                                for: item,
                                isLastInSection: store.state.searchResults.last == item
                            )
                            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                        }
                        .accessibilityIdentifier("ItemCell")
                    }
                }
            }
        } else {
            SearchNoResultsView()
        }
    }

    // MARK: Private Methods

    /// A view that displays a list of the sections within this vault group.
    ///
    @ViewBuilder
    private func groupView(with items: [ItemListItem]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 7) {
                ForEach(items) { item in
                    Button {
                        store.send(.itemPressed(item))
                    } label: {
                        vaultItemRow(
                            for: item,
                            isLastInSection: true
                        )
                    }
                }
                .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(16)
        }
    }

    /// Creates a row in the list for the provided item.
    ///
    /// - Parameters:
    ///   - item: The `ItemListItem` to use when creating the view.
    ///   - isLastInSection: A flag indicating if this item is the last one in the section.
    ///
    @ViewBuilder
    private func vaultItemRow(for item: ItemListItem, isLastInSection: Bool = false) -> some View {
        ItemListItemRowView(
            store: store.child(
                state: { state in
                    ItemListItemRowState(
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

// MARK: - ItemListView

/// The main view of the item list
struct ItemListView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<ItemListState, ItemListAction, ItemListEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    var body: some View {
        ZStack {
            SearchableItemListView(
                store: store,
                timeProvider: timeProvider
            )
            .searchable(
                text: store.binding(
                    get: \.searchText,
                    send: ItemListAction.searchTextChanged
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Localizations.search
            )
            .task(id: store.state.searchText) {
                await store.perform(.search(store.state.searchText))
            }
            .refreshable {
                await store.perform(.refresh)
            }
        }
        .navigationTitle(Localizations.verificationCodes)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            addToolbarItem(hidden: !store.state.showAddToolbarItem) {
                Task {
                    await store.perform(.addItemPressed)
                }
            }
        }
        .task {
            await store.perform(.appeared)
        }
    }
}

// MARK: Previews

#if DEBUG
struct ItemListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            loadingState: .loading(nil)
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("Loading")

        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            loadingState: .data([])
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("Empty")

        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            loadingState: .data(
                                [
                                    ItemListItem(
                                        id: "One",
                                        name: "One",
                                        itemType: .totp(
                                            model: ItemListTotpItem(
                                                itemView: AuthenticatorItemView.fixture(),
                                                totpCode: TOTPCodeModel(
                                                    code: "123456",
                                                    codeGenerationDate: Date(),
                                                    period: 30
                                                )
                                            )
                                        )
                                    ),
                                    ItemListItem(
                                        id: "Two",
                                        name: "Two",
                                        itemType: .totp(
                                            model: ItemListTotpItem(
                                                itemView: AuthenticatorItemView.fixture(),
                                                totpCode: TOTPCodeModel(
                                                    code: "123456",
                                                    codeGenerationDate: Date(),
                                                    period: 30
                                                )
                                            )
                                        )
                                    ),
                                ]
                            )
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("Items")

        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            searchResults: [],
                            searchText: "Example"
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("0 Search Results")

        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            searchResults: [
                                ItemListItem(
                                    id: "One",
                                    name: "One",
                                    itemType: .totp(
                                        model: ItemListTotpItem(
                                            itemView: AuthenticatorItemView.fixture(),
                                            totpCode: TOTPCodeModel(
                                                code: "123456",
                                                codeGenerationDate: Date(),
                                                period: 30
                                            )
                                        )
                                    )
                                ),
                            ],
                            searchText: "One"
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("1 Search Result")

        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            searchResults: [
                                ItemListItem(
                                    id: "One",
                                    name: "One",
                                    itemType: .totp(
                                        model: ItemListTotpItem(
                                            itemView: AuthenticatorItemView.fixture(),
                                            totpCode: TOTPCodeModel(
                                                code: "123456",
                                                codeGenerationDate: Date(),
                                                period: 30
                                            )
                                        )
                                    )
                                ),
                                ItemListItem(
                                    id: "Two",
                                    name: "One Direction",
                                    itemType: .totp(
                                        model: ItemListTotpItem(
                                            itemView: AuthenticatorItemView.fixture(),
                                            totpCode: TOTPCodeModel(
                                                code: "123456",
                                                codeGenerationDate: Date(),
                                                period: 30
                                            )
                                        )
                                    )
                                ),
                                ItemListItem(
                                    id: "Three",
                                    name: "One Song",
                                    itemType: .totp(
                                        model: ItemListTotpItem(
                                            itemView: AuthenticatorItemView.fixture(),
                                            totpCode: TOTPCodeModel(
                                                code: "123456",
                                                codeGenerationDate: Date(),
                                                period: 30
                                            )
                                        )
                                    )
                                ),
                            ],
                            searchText: "One"
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("3 Search Results")
    }
}
#endif
