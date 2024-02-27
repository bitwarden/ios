import SwiftUI

// swiftlint:disable file_length

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
            .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
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
            .task(id: store.state.vaultFilterType) {
                await store.perform(.streamVaultList)
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
                    vaultFilterRow
                        .padding(.top, 16)

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

    /// A view that displays either thegroup or empty interface.
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
                            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
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
                state: { state in
                    SearchVaultFilterRowState(
                        organizations: state.organizations,
                        searchVaultFilterType: state.searchVaultFilterType,
                        isPersonalOwnershipDisabled: state.isPersonalOwnershipDisabled
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

    /// Displays the vault filter row if the user is a member of any.
    ///
    private var vaultFilterRow: some View {
        SearchVaultFilterRowView(
            hasDivider: false,
            accessibilityID: store.state.filterAccessibilityID,
            store: store.child(
                state: { state in
                    SearchVaultFilterRowState(
                        organizations: state.organizations,
                        searchVaultFilterType: state.vaultFilterType,
                        isPersonalOwnershipDisabled: state.isPersonalOwnershipDisabled
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

    // MARK: Private Methods

    /// A view that displays a list of the contents of this vault group.
    ///
    @ViewBuilder
    private func groupView(with items: [VaultListItem]) -> some View {
        ScrollView {
            VStack(spacing: 20.0) {
                vaultFilterRow

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(Localizations.items.uppercased())
                        Spacer()
                        Text("\(items.count)")
                    }
                    .font(.footnote)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)

                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { item in
                            Button {
                                store.send(.itemPressed(item))
                            } label: {
                                vaultItemRow(
                                    for: item,
                                    isLastInSection: items.last == item
                                )
                            }
                        }
                    }
                    .background(Asset.Colors.backgroundPrimary.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    case .morePressed:
                        return .morePressed(item)
                    }
                },
                mapEffect: nil
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
                        loadingState: .data([
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
                                attachments: [],
                                fields: [],
                                passwordHistory: [],
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
                                attachments: [],
                                fields: [],
                                passwordHistory: [],
                                creationDate: Date(),
                                deletedDate: nil,
                                revisionDate: Date()
                            ))!,
                        ]),
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
