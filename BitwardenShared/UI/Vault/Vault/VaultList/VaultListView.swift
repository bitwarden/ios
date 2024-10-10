// swiftlint:disable file_length

import BitwardenSdk
import SwiftUI

// MARK: - SearchableVaultListView

/// The main view of the vault.
private struct SearchableVaultListView: View {
    // MARK: Properties

    /// A flag indicating if the search bar is focused.
    @Environment(\.isSearching) private var isSearching

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, VaultListEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

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

            vault
                .hidden(isSearching)

            search
                .hidden(!isSearching)
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
        .toast(store.binding(
            get: \.toast,
            send: VaultListAction.toastShown
        ))
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
        .onChange(of: isSearching) { newValue in
            store.send(.searchStateChanged(isSearching: newValue))
        }
        .toast(store.binding(
            get: \.toast,
            send: VaultListAction.toastShown
        ))
        .animation(.default, value: isSearching)
        .toast(store.binding(
            get: \.toast,
            send: VaultListAction.toastShown
        ))
    }

    // MARK: Private Properties

    /// A view that displays the empty vault interface.
    @ViewBuilder private var emptyVault: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 24) {
                    vaultFilterRow
                        .padding(.top, 16)

                    Spacer()

                    PageHeaderView(
                        image: Asset.Images.items,
                        title: Localizations.saveAndProtectYourData,
                        message: Localizations
                            .theVaultProtectsMoreThanJustPasswordsStoreSecureLoginsIdsCardsAndNotesSecurelyHere
                    )
                    .padding(.horizontal, 16)

                    Button {
                        store.send(.addItemPressed)
                    } label: {
                        HStack {
                            Image(decorative: Asset.Images.plus)
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text(Localizations.newLogin)
                        }
                        .padding(.horizontal, 24)
                    }
                    .buttonStyle(.primary(shouldFillWidth: false))

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
                    searchVaultFilterRow

                    ForEach(store.state.searchResults) { item in
                        Button {
                            store.send(.itemPressed(item: item))
                        } label: {
                            vaultItemRow(
                                for: item,
                                isLastInSection: store.state.searchResults.last == item
                            )
                            .background(Asset.Colors.backgroundSecondary.swiftUIColor)
                        }
                        .accessibilityIdentifier("CipherCell")
                    }
                }
            }
        } else {
            SearchNoResultsView {
                searchVaultFilterRow
            }
        }
    }

    /// Displays the vault filter for search row if the user is a member of any org.
    private var searchVaultFilterRow: some View {
        SearchVaultFilterRowView(
            hasDivider: true, store: store.child(
                state: \.searchVaultFilterState,
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

    /// A view that displays either the my vault or empty vault interface.
    @ViewBuilder private var vault: some View {
        LoadingView(state: store.state.loadingState) { sections in
            if sections.isEmpty {
                emptyVault
            } else {
                vaultContents(with: sections)
            }
        }
    }

    /// Displays the vault filter row if the user is a member of any.
    private var vaultFilterRow: some View {
        SearchVaultFilterRowView(
            hasDivider: false,
            accessibilityID: "ActiveFilterRow",
            store: store.child(
                state: \.vaultFilterState,
                mapAction: { action in
                    switch action {
                    case let .searchVaultFilterChanged(type):
                        return .vaultFilterChanged(type)
                    }
                },
                mapEffect: nil
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Private Methods

    /// A view that displays the main vault interface, including sections for groups and
    /// vault items.
    ///
    /// - Parameter sections: The sections of the vault list to display.
    ///
    @ViewBuilder
    private func vaultContents(with sections: [VaultListSection]) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                vaultFilterRow

                ForEach(sections) { section in
                    VaultListSectionView(section: section) { item in
                        Button {
                            store.send(.itemPressed(item: item))
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
                        showWebIcons: state.showWebIcons,
                        isFromExtension: false
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
        .accessibilityIdentifier("CipherCell")
    }
}

// MARK: - VaultListView

/// A view that allows the user to view a list of the items in their vault.
///
struct VaultListView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, VaultListEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    var body: some View {
        ZStack {
            SearchableVaultListView(
                store: store,
                timeProvider: timeProvider
            )
            .searchable(
                text: store.binding(
                    get: \.searchText,
                    send: VaultListAction.searchTextChanged
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Localizations.search
            )
            .task(id: store.state.searchText) {
                await store.perform(.search(store.state.searchText))
            }
            .task(id: store.state.searchVaultFilterType) {
                await store.perform(.search(store.state.searchText))
            }
            .refreshable { [weak store] in
                await store?.perform(.refreshVault)
            }
            profileSwitcher
        }
        .navigationTitle(store.state.navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ProfileSwitcherToolbarView(
                    store: store.child(
                        state: { state in
                            state.profileSwitcherState
                        },
                        mapAction: { action in
                            .profileSwitcher(action)
                        },
                        mapEffect: { effect in
                            .profileSwitcher(effect)
                        }
                    )
                )
            }
            addToolbarItem {
                store.send(.addItemPressed)
            }
        }
        .task {
            await store.perform(.refreshAccountProfiles)
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
        .task(id: store.state.vaultFilterType) {
            await store.perform(.streamVaultList)
        }
    }

    // MARK: Private properties

    /// A view that displays the ability to add or switch between account profiles
    @ViewBuilder private var profileSwitcher: some View {
        ProfileSwitcherView(
            store: store.child(
                state: { vaultListState in
                    vaultListState.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcher(action)
                },
                mapEffect: { effect in
                    .profileSwitcher(effect)
                }
            )
        )
    }
}

// MARK: Previews

#if DEBUG
// swiftlint:disable:next type_body_length
struct VaultListView_Previews: PreviewProvider {
    static let account1 = ProfileSwitcherItem.fixture(
        color: .purple,
        email: "Anne.Account@bitwarden.com",
        isUnlocked: true,
        userId: "1",
        userInitials: "AA",
        webVault: "vault.bitwarden.com"
    )

    static let account2 = ProfileSwitcherItem.fixture(
        color: .green,
        email: "bonus.bridge@bitwarden.com",
        isUnlocked: true,
        userId: "2",
        userInitials: "BB",
        webVault: "vault.bitwarden.com"
    )

    static let singleAccountState = ProfileSwitcherState(
        accounts: [account1],
        activeAccountId: account1.userId,
        allowLockAndLogout: true,
        isVisible: true
    )

    static let dualAccountState = ProfileSwitcherState(
        accounts: [account1, account2],
        activeAccountId: account1.userId,
        allowLockAndLogout: true,
        isVisible: true
    )

    static var previews: some View {
        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState()
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("Loading")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([])
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("Empty")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([
                                VaultListSection(
                                    id: "1",
                                    items: [
                                        .init(cipherView: .fixture(
                                            id: UUID().uuidString,
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example"
                                        ))!,
                                        .init(cipherView: .fixture(
                                            id: UUID().uuidString,
                                            name: "Example 2",
                                            type: .secureNote
                                        ))!,
                                    ],
                                    name: "Favorites"
                                ),
                                VaultListSection(
                                    id: "2",
                                    items: [
                                        VaultListItem(
                                            id: "21",
                                            itemType: .group(.login, 123)
                                        ),
                                        VaultListItem(
                                            id: "22",
                                            itemType: .group(.card, 25)
                                        ),
                                        VaultListItem(
                                            id: "23",
                                            itemType: .group(.identity, 1)
                                        ),
                                        VaultListItem(
                                            id: "24",
                                            itemType: .group(.secureNote, 0)
                                        ),
                                    ],
                                    name: "Types"
                                ),
                            ])
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("My Vault")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([
                                VaultListSection(
                                    id: "Collections",
                                    items: [
                                        VaultListItem(
                                            id: "31",
                                            itemType: .group(
                                                .collection(id: "", name: "Design", organizationId: "1"),
                                                0
                                            )
                                        ),
                                        VaultListItem(
                                            id: "32",
                                            itemType: .group(
                                                .collection(id: "", name: "Engineering", organizationId: "1"),
                                                2
                                            )
                                        ),
                                    ],
                                    name: "Collections"
                                ),
                                VaultListSection(
                                    id: "CollectionItems",
                                    items: [
                                        .init(cipherView: .fixture(
                                            id: UUID().uuidString,
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example",
                                            organizationId: "1"
                                        ))!,
                                    ],
                                    name: "Items"
                                ),
                            ]),
                            organizations: [
                                Organization(
                                    enabled: true,
                                    id: "",
                                    key: nil,
                                    keyConnectorEnabled: false,
                                    keyConnectorUrl: nil,
                                    name: "Org",
                                    permissions: Permissions(),
                                    status: .confirmed,
                                    type: .user,
                                    useEvents: false,
                                    usePolicies: true,
                                    usersGetPremium: false
                                ),
                            ]
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("My Vault - Collections")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            profileSwitcherState: ProfileSwitcherState(
                                accounts: [],
                                activeAccountId: nil,
                                allowLockAndLogout: true,
                                isVisible: false
                            ),
                            searchResults: [
                                .init(cipherView: .fixture(
                                    id: UUID().uuidString,
                                    login: .fixture(username: "email@example.com"),
                                    name: "Example"
                                ))!,
                            ],
                            searchText: "Exam"
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("1 Search Result")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            searchResults: [
                                .init(cipherView: .fixture(
                                    id: UUID().uuidString,
                                    login: .fixture(username: "email@example.com"),
                                    name: "Example"
                                ))!,
                                .init(cipherView: .fixture(
                                    id: UUID().uuidString,
                                    login: .fixture(username: "email2@example.com"),
                                    name: "Example 2"
                                ))!,
                                .init(cipherView: .fixture(
                                    id: UUID().uuidString,
                                    login: .fixture(username: "email3@example.com"),
                                    name: "Example 3"
                                ))!,
                            ],
                            searchText: "Exam"
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("3 Search Results")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            searchResults: [],
                            searchText: "Exam"
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("No Search Results")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([]),
                            profileSwitcherState: .singleAccount
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("Profile Switcher Visible: Single Account")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([]),
                            profileSwitcherState: .dualAccounts
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("Profile Switcher Visible: Multi Account")
    }
}
#endif
