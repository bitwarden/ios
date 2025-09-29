import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - VaultItemSelectionView

/// A view that allows the user see a list of their vault item for autofill.
///
struct VaultItemSelectionView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultItemSelectionState, VaultItemSelectionAction, VaultItemSelectionEffect>

    // MARK: View

    var body: some View {
        ZStack {
            VaultItemSelectionSearchableView(store: store)

            profileSwitcher
        }
        .navigationBar(
            title: Localizations.itemsForUri(store.state.ciphersMatchingName ?? "--"),
            titleDisplayMode: .inline
        )
        .searchable(
            text: store.binding(
                get: \.searchText,
                send: VaultItemSelectionAction.searchTextChanged
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Localizations.search
        )
        .toolbar {
            cancelToolbarItem {
                store.send(.cancelTapped)
            }

            ToolbarItem(placement: .navigationBarLeading) {
                ProfileSwitcherToolbarView(
                    store: store.child(
                        state: \.profileSwitcherState,
                        mapAction: VaultItemSelectionAction.profileSwitcher,
                        mapEffect: VaultItemSelectionEffect.profileSwitcher
                    )
                )
            }
        }
    }

    // MARK: Private properties

    /// A view that displays the ability to add or switch between account profiles
    @ViewBuilder private var profileSwitcher: some View {
        ProfileSwitcherView(
            store: store.child(
                state: \.profileSwitcherState,
                mapAction: VaultItemSelectionAction.profileSwitcher,
                mapEffect: VaultItemSelectionEffect.profileSwitcher
            )
        )
    }
}

// MARK: - VaultItemSelectionSearchableView

/// A view that that displays the content of `VaultItemSelectionView`. This needs to be a separate
/// view from `VaultItemSelectionView` to enable the `isSearching` environment variable within this
/// view.
///
private struct VaultItemSelectionSearchableView: View {
    // MARK: Properties

    /// The message to display when there's no search results.
    var emptyViewMessage: String {
        Localizations.thereAreNoItemsInYourVaultThatMatchX(
            store.state.ciphersMatchingName ?? "--"
        ) + "\n" + Localizations.searchForAnItemOrAddANewItem
    }

    /// A flag indicating if the search bar is focused.
    @Environment(\.isSearching) private var isSearching

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultItemSelectionState, VaultItemSelectionAction, VaultItemSelectionEffect>

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

            contentView()
                .overlay(alignment: .bottomTrailing) {
                    addItemFloatingActionButton {
                        store.send(.addTapped)
                    }
                }
                .hidden(isSearching)

            searchContentView()
                .hidden(!isSearching)
        }
        .onChange(of: isSearching) { newValue in
            store.send(.searchStateChanged(isSearching: newValue))
        }
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
        .task {
            await store.perform(.loadData)
        }
        .task {
            await store.perform(.streamShowWebIcons)
        }
        .task {
            await store.perform(.streamVaultItems)
        }
        .task(id: store.state.searchText) {
            await store.perform(.search(store.state.searchText))
        }
        .toast(
            store.binding(
                get: \.toast,
                send: VaultItemSelectionAction.toastShown
            ),
            additionalBottomPadding: FloatingActionButton.bottomOffsetPadding
        )
        .background(Color(asset: SharedAsset.Colors.backgroundPrimary).ignoresSafeArea())
    }

    // MARK: Private Views

    /// The content displayed in the view.
    @ViewBuilder
    private func contentView() -> some View {
        if store.state.vaultListSections.isEmpty {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.items.swiftUIImage,
                message: emptyViewMessage
            ) {
                Button {
                    store.send(.addTapped)
                } label: {
                    Label {
                        Text(Localizations.newItem)
                    } icon: {
                        Asset.Images.plus16.swiftUIImage
                            .imageStyle(.accessoryIcon16(
                                color: SharedAsset.Colors.buttonFilledForeground.swiftUIColor,
                                scaleWithFont: true
                            ))
                    }
                }
                .buttonStyle(.primary(shouldFillWidth: false))
            }
            .scrollView(centerContentVertically: true)
        } else {
            matchingItemsView()
        }
    }

    /// A view for displaying the list of items that match the OTP key.
    @ViewBuilder
    private func matchingItemsView() -> some View {
        VStack(spacing: 16) {
            InfoContainer(Localizations.addTheKeyToAnExistingOrNewItem)

            ForEach(store.state.vaultListSections) { section in
                VaultListSectionView(section: section) { item in
                    vaultListItemView(item, hasDivider: section.items.last != item)
                }
            }
        }
        .padding(.bottom, FloatingActionButton.bottomOffsetPadding)
        .scrollView()
    }

    /// A view for displaying the cipher search results.
    @ViewBuilder
    private func searchContentView() -> some View {
        if store.state.showNoResults {
            SearchNoResultsView()
        } else {
            searchResultItemsView()
        }
    }

    /// A view for displaying the search result items.
    @ViewBuilder
    private func searchResultItemsView() -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.state.searchResults) { item in
                    vaultListItemView(item, hasDivider: store.state.searchResults.last != item)
                }
            }
            .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
        }
    }

    /// A view for displaying a `VaultListItem`.
    @ViewBuilder
    private func vaultListItemView(_ item: VaultListItem, hasDivider: Bool) -> some View {
        AsyncButton {
            await store.perform(.vaultListItemTapped(item))
        } label: {
            VaultListItemRowView(
                store: store.child(
                    state: { state in
                        VaultListItemRowState(
                            iconBaseURL: state.iconBaseURL,
                            item: item,
                            hasDivider: hasDivider,
                            showWebIcons: state.showWebIcons
                        )
                    },
                    mapAction: nil, // No actions are supported (TOTP copy is handled by the more pressed effect).
                    mapEffect: { effect in
                        switch effect {
                        case .morePressed:
                            return .morePressed(item)
                        }
                    }
                ),
                timeProvider: CurrentTime()
            )
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty") {
    NavigationView {
        VaultItemSelectionView(store: Store(processor: StateProcessor(
            state: VaultItemSelectionState(iconBaseURL: nil, totpKeyModel: .fixtureExample)
        )))
    }
}

#Preview("Search Results") {
    NavigationView {
        VaultItemSelectionView(
            store: Store(
                processor: StateProcessor(
                    state: VaultItemSelectionState(
                        iconBaseURL: nil,
                        searchResults: [.init(id: "1", itemType: .cipher(.fixture()))],
                        searchText: "Search",
                        totpKeyModel: .fixtureExample
                    )
                )
            )
        )
    }
}

#Preview("Matching Items") {
    NavigationView {
        let ciphers: [CipherListView] = [
            .fixture(
                id: "1",
                login: .fixture(username: "user@bitwarden.com"),
                name: "Apple"
            ),
            .fixture(
                id: "2",
                login: .fixture(username: "user@bitwarden.com"),
                name: "Bitwarden"
            ),
            .fixture(
                id: "3",
                name: "Company XYZ"
            ),
            .fixture(
                id: "4",
                login: .fixture(username: "user@bitwarden.com"),
                name: "Apple"
            ),
            .fixture(
                id: "5",
                login: .fixture(username: "user@bitwarden.com"),
                name: "Bitwarden"
            ),
            .fixture(
                id: "6",
                name: "Company XYZ"
            ),
            .fixture(
                id: "7",
                login: .fixture(username: "user@bitwarden.com"),
                name: "Apple"
            ),
            .fixture(
                id: "8",
                login: .fixture(username: "user@bitwarden.com"),
                name: "Bitwarden"
            ),
            .fixture(
                id: "9",
                name: "Company XYZ"
            ),
        ]
        VaultItemSelectionView(
            store: Store(
                processor: StateProcessor(
                    state: VaultItemSelectionState(
                        iconBaseURL: nil,
                        totpKeyModel: .fixtureExample,
                        vaultListSections: [
                            VaultListSection(
                                id: Localizations.matchingItems,
                                items: ciphers.compactMap(VaultListItem.init),
                                name: Localizations.matchingItems
                            ),
                        ]
                    )
                )
            )
        )
    }
}
#endif
