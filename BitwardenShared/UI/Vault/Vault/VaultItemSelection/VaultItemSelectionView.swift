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
            ToolbarItem(placement: .navigationBarLeading) {
                ProfileSwitcherToolbarView(
                    store: store.child(
                        state: \.profileSwitcherState,
                        mapAction: VaultItemSelectionAction.profileSwitcher,
                        mapEffect: VaultItemSelectionEffect.profileSwitcher
                    )
                )
            }

            addToolbarItem {
                store.send(.addTapped)
            }

            cancelToolbarItem {
                store.send(.cancelTapped)
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

    /// A flag indicating if the search bar is focused.
    @Environment(\.isSearching) private var isSearching

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultItemSelectionState, VaultItemSelectionAction, VaultItemSelectionEffect>

    // MARK: View

    var body: some View {
        contentView()
            .onChange(of: isSearching) { newValue in
                store.send(.searchStateChanged(isSearching: newValue))
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
            .toast(store.binding(
                get: \.toast,
                send: VaultItemSelectionAction.toastShown
            ))
            .background(Color(asset: Asset.Colors.backgroundSecondary).ignoresSafeArea())
    }

    // MARK: Private Views

    /// The content displayed in the view.
    @ViewBuilder
    private func contentView() -> some View {
        if isSearching {
            searchContentView()
        } else {
            if store.state.vaultListSections.isEmpty {
                GeometryReader { reader in
                    VStack(spacing: 24) {
                        Asset.Images.openSource.swiftUIImage
                            .resizable()
                            .frame(width: 100, height: 100)
                            .padding(.bottom, 8)

                        Text(
                            Localizations.thereAreNoItemsInYourVaultThatMatchX(
                                store.state.ciphersMatchingName ?? "--"
                            ) +
                                "\n" +
                                Localizations.searchForAnItemOrAddANewItem
                        )
                        .styleGuide(.callout)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .multilineTextAlignment(.center)

                        Button {
                            store.send(.addTapped)
                        } label: {
                            HStack(spacing: 8) {
                                Asset.Images.plus.swiftUIImage
                                    .imageStyle(.accessoryIcon(
                                        color: Asset.Colors.textPrimaryInverted.swiftUIColor,
                                        scaleWithFont: true
                                    ))

                                Text(Localizations.addAnItem)
                            }
                        }
                        .buttonStyle(.primary(shouldFillWidth: false))
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, minHeight: reader.size.height)
                    .scrollView(addVerticalPadding: false)
                }
            } else {
                matchingItemsView()
            }
        }
    }

    /// A view for displaying the list of items that match the OTP key.
    @ViewBuilder
    private func matchingItemsView() -> some View {
        VStack(spacing: 16) {
            InfoContainer(Localizations.addTheKeyToAnExistingOrNewItem, textAlignment: .leading)

            ForEach(store.state.vaultListSections) { section in
                VaultListSectionView(section: section) { item in
                    vaultListItemView(item, hasDivider: section.items.last != item)
                }
            }
        }
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
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
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
                    mapAction: nil, // TODO: BIT-2349 Allow users to add authenticator key to existing items
                    mapEffect: nil // TODO: BIT-2349 Allow users to add authenticator key to existing items
                ),
                timeProvider: CurrentTime()
            )
            .accessibilityIdentifier("CipherCell")
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty") {
    NavigationView {
        VaultItemSelectionView(store: Store(processor: StateProcessor(
            state: VaultItemSelectionState(iconBaseURL: nil, otpAuthModel: .fixtureExample)
        )))
    }
}

#Preview("Matching Items") {
    NavigationView {
        let ciphers: [CipherView] = [
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
        ]
        VaultItemSelectionView(
            store: Store(
                processor: StateProcessor(
                    state: VaultItemSelectionState(
                        iconBaseURL: nil,
                        otpAuthModel: .fixtureExample,
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
