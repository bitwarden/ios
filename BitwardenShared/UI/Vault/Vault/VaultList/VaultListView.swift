// swiftlint:disable file_length

import BitwardenSdk
import SwiftUI

// MARK: - VaultMainView

/// The main view of the vault.
private struct VaultMainView: View {
    // MARK: Properties

    /// A flag indicating if the search bar is focused.
    @Environment(\.isSearching) private var isSearching

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, VaultListEffect>

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
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
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
                    vaultFilterRow()
                        .padding(.top, 16)

                    Spacer()

                    Text(Localizations.noItems)
                        .multilineTextAlignment(.center)
                        .styleGuide(.callout)
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
                    searchVaultFilterRow

                    ForEach(store.state.searchResults) { item in
                        Button {
                            store.send(.itemPressed(item: item))
                        } label: {
                            vaultItemRow(
                                for: item,
                                isLastInSection: store.state.searchResults.last == item
                            )
                            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                        }
                    }
                }
            }
        } else {
            GeometryReader { reader in
                ScrollView {
                    VStack(spacing: 0) {
                        searchVaultFilterRow

                        VStack(spacing: 35) {
                            Image(decorative: Asset.Images.magnifyingGlass)
                                .resizable()
                                .frame(width: 74, height: 74)
                                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                            Text(Localizations.thereAreNoItemsThatMatchTheSearch)
                                .multilineTextAlignment(.center)
                                .styleGuide(.callout)
                                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        }
                        .frame(maxWidth: .infinity, minHeight: reader.size.height, maxHeight: .infinity)
                    }
                }
            }
        }
    }

    /// Displays the vault filter for search row if the user is a member of any org
    private var searchVaultFilterRow: some View {
        SearchVaultFilterRowView(
            hasDivider: true, store: store.child(
                state: { state in
                    SearchVaultFilterRowState(
                        organizations: state.organizations,
                        searchVaultFilterType: state.searchVaultFilterType
                    )
                },
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

    // MARK: Private Methods

    /// A view that displays the main vault interface, including sections for groups and
    /// vault items.
    ///
    /// - Parameter sections: The sections of the vault list to display.
    ///
    @ViewBuilder
    private func vaultContents(with sections: [VaultListSection]) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                vaultFilterRow()

                ForEach(sections) { section in
                    vaultItemSectionView(title: section.name, items: section.items)
                }
            }
            .padding(16)
        }
    }

    /// Displays the vault filter row if the user is a member of any
    @ViewBuilder
    private func vaultFilterRow() -> some View {
        SearchVaultFilterRowView(
            hasDivider: false, store: store.child(
                state: { state in
                    SearchVaultFilterRowState(
                        organizations: state.organizations,
                        searchVaultFilterType: state.vaultFilterType
                    )
                },
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

    /// Creates a row in the list for the provided item.
    ///
    /// - Parameters:
    ///   - item: The `VaultListItem` to use when creating the view.
    ///   - isLastInSection: A flag indicating if this item is the last one in the section.
    ///
    @ViewBuilder
    private func vaultItemRow(for item: VaultListItem, isLastInSection: Bool = false) -> some View {
        VaultListItemRowView(store: store.child(
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
                case .morePressed:
                    return .morePressed(item)
                }
            },
            mapEffect: nil
        ))
    }

    /// Creates a section that appears in the vault.
    ///
    /// - Parameters:
    ///   - title: The title of the section.
    ///   - items: The `VaultListItem`s in this section.
    ///
    @ViewBuilder
    private func vaultItemSectionView(title: String, items: [VaultListItem]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeaderView(title)
                Spacer()
                SectionHeaderView("\(items.count)")
            }

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(items) { item in
                    Button {
                        store.send(.itemPressed(item: item))
                    } label: {
                        vaultItemRow(for: item, isLastInSection: items.last == item)
                    }
                }
            }
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - VaultListView

/// A view that allows the user to view a list of the items in their vault.
///
struct VaultListView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, VaultListEffect>

    var body: some View {
        ZStack {
            VaultMainView(store: store)
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
                .refreshable {
                    await store.perform(.refreshVault)
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
                            .profileSwitcherAction(action)
                        },
                        mapEffect: nil
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
                    .profileSwitcherAction(action)
                },
                mapEffect: nil
            )
        )
    }
}

// MARK: Previews

#if DEBUG
// swiftlint:disable:next type_body_length
struct VaultListView_Previews: PreviewProvider {
    static let account1 = ProfileSwitcherItem(
        color: .purple,
        email: "Anne.Account@bitwarden.com",
        userInitials: "AA"
    )

    static let account2 = ProfileSwitcherItem(
        color: .green,
        email: "bonus.bridge@bitwarden.com",
        isUnlocked: true,
        userInitials: "BB"
    )

    static let singleAccountState = ProfileSwitcherState(
        accounts: [account1],
        activeAccountId: account1.userId,
        isVisible: true
    )

    static let dualAccountState = ProfileSwitcherState(
        accounts: [account1, account2],
        activeAccountId: account1.userId,
        isVisible: true
    )

    static var previews: some View {
        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState()
                    )
                )
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
                )
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
                                        .init(cipherView: .init(
                                            id: UUID().uuidString,
                                            organizationId: nil,
                                            folderId: nil,
                                            collectionIds: [],
                                            key: nil,
                                            name: "Example",
                                            notes: nil,
                                            type: .login,
                                            login: .init(
                                                username: "email@example.com",
                                                password: nil,
                                                passwordRevisionDate: nil,
                                                uris: nil,
                                                totp: nil,
                                                autofillOnPageLoad: nil
                                            ),
                                            identity: nil,
                                            card: nil,
                                            secureNote: nil,
                                            favorite: true,
                                            reprompt: .none,
                                            organizationUseTotp: false,
                                            edit: false,
                                            viewPassword: true,
                                            localData: nil,
                                            attachments: nil,
                                            fields: nil,
                                            passwordHistory: nil,
                                            creationDate: Date(),
                                            deletedDate: nil,
                                            revisionDate: Date()
                                        ))!,
                                        .init(cipherView: .init(
                                            id: UUID().uuidString,
                                            organizationId: nil,
                                            folderId: nil,
                                            collectionIds: [],
                                            key: nil,
                                            name: "Example 2",
                                            notes: nil,
                                            type: .secureNote,
                                            login: nil,
                                            identity: nil,
                                            card: nil,
                                            secureNote: nil,
                                            favorite: true,
                                            reprompt: .none,
                                            organizationUseTotp: false,
                                            edit: false,
                                            viewPassword: true,
                                            localData: nil,
                                            attachments: nil,
                                            fields: nil,
                                            passwordHistory: nil,
                                            creationDate: Date(),
                                            deletedDate: nil,
                                            revisionDate: Date()
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
                )
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
                                            itemType: .group(.collection(id: "", name: "Design"), 0)
                                        ),
                                        VaultListItem(
                                            id: "32",
                                            itemType: .group(.collection(id: "", name: "Engineering"), 2)
                                        ),
                                    ],
                                    name: "Collections"
                                ),
                                VaultListSection(
                                    id: "CollectionItems",
                                    items: [
                                        .init(cipherView: .init(
                                            id: UUID().uuidString,
                                            organizationId: "1",
                                            folderId: nil,
                                            collectionIds: [],
                                            key: nil,
                                            name: "Example",
                                            notes: nil,
                                            type: .login,
                                            login: .init(
                                                username: "email@example.com",
                                                password: nil,
                                                passwordRevisionDate: nil,
                                                uris: nil,
                                                totp: nil,
                                                autofillOnPageLoad: nil
                                            ),
                                            identity: nil,
                                            card: nil,
                                            secureNote: nil,
                                            favorite: true,
                                            reprompt: .none,
                                            organizationUseTotp: false,
                                            edit: false,
                                            viewPassword: true,
                                            localData: nil,
                                            attachments: nil,
                                            fields: nil,
                                            passwordHistory: nil,
                                            creationDate: Date(),
                                            deletedDate: nil,
                                            revisionDate: Date()
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
                                    name: "Org",
                                    status: .confirmed
                                ),
                            ]
                        )
                    )
                )
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
                                isVisible: false
                            ),
                            searchResults: [
                                .init(cipherView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    key: nil,
                                    name: "Example",
                                    notes: nil,
                                    type: .login,
                                    login: .init(
                                        username: "email@example.com",
                                        password: nil,
                                        passwordRevisionDate: nil,
                                        uris: nil,
                                        totp: nil,
                                        autofillOnPageLoad: nil
                                    ),
                                    identity: nil,
                                    card: nil,
                                    secureNote: nil,
                                    favorite: true,
                                    reprompt: .none,
                                    organizationUseTotp: false,
                                    edit: false,
                                    viewPassword: true,
                                    localData: nil,
                                    attachments: nil,
                                    fields: nil,
                                    passwordHistory: nil,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                            ],
                            searchText: "Exam"
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
                            searchResults: [
                                .init(cipherView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    key: nil,
                                    name: "Example",
                                    notes: nil,
                                    type: .login,
                                    login: .init(
                                        username: "email@example.com",
                                        password: nil,
                                        passwordRevisionDate: nil,
                                        uris: nil,
                                        totp: nil,
                                        autofillOnPageLoad: nil
                                    ),
                                    identity: nil,
                                    card: nil,
                                    secureNote: nil,
                                    favorite: true,
                                    reprompt: .none,
                                    organizationUseTotp: false,
                                    edit: false,
                                    viewPassword: true,
                                    localData: nil,
                                    attachments: nil,
                                    fields: nil,
                                    passwordHistory: nil,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                                .init(cipherView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    key: nil,
                                    name: "Example 2",
                                    notes: nil,
                                    type: .login,
                                    login: .init(
                                        username: "email2@example.com",
                                        password: nil,
                                        passwordRevisionDate: nil,
                                        uris: nil,
                                        totp: nil,
                                        autofillOnPageLoad: nil
                                    ),
                                    identity: nil,
                                    card: nil,
                                    secureNote: nil,
                                    favorite: true,
                                    reprompt: .none,
                                    organizationUseTotp: false,
                                    edit: false,
                                    viewPassword: true,
                                    localData: nil,
                                    attachments: nil,
                                    fields: nil,
                                    passwordHistory: nil,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                                .init(cipherView: .init(
                                    id: UUID().uuidString,
                                    organizationId: nil,
                                    folderId: nil,
                                    collectionIds: [],
                                    key: nil,
                                    name: "Example 3",
                                    notes: nil,
                                    type: .login,
                                    login: .init(
                                        username: "email3@example.com",
                                        password: nil,
                                        passwordRevisionDate: nil,
                                        uris: nil,
                                        totp: nil,
                                        autofillOnPageLoad: nil
                                    ),
                                    identity: nil,
                                    card: nil,
                                    secureNote: nil,
                                    favorite: true,
                                    reprompt: .none,
                                    organizationUseTotp: false,
                                    edit: false,
                                    viewPassword: true,
                                    localData: nil,
                                    attachments: nil,
                                    fields: nil,
                                    passwordHistory: nil,
                                    creationDate: Date(),
                                    deletedDate: nil,
                                    revisionDate: Date()
                                ))!,
                            ],
                            searchText: "Exam"
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
                            searchResults: [],
                            searchText: "Exam"
                        )
                    )
                )
            )
        }
        .previewDisplayName("No Search Results")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([]),
                            profileSwitcherState: singleAccountState
                        )
                    )
                )
            )
        }
        .previewDisplayName("Profile Switcher Visible: Single Account")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([]),
                            profileSwitcherState: dualAccountState
                        )
                    )
                )
            )
        }
        .previewDisplayName("Profile Switcher Visible: Multi Account")
    }
}
#endif
