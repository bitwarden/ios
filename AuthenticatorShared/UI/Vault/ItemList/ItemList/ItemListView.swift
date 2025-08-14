// swiftlint:disable file_length

import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - SearchableItemListView

/// A view that displays the items in a single vault group.
private struct SearchableItemListView: View { // swiftlint:disable:this type_body_length
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
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
    }

    // MARK: Private

    /// The card section to display at the top of the list.
    @ViewBuilder private var cardSection: some View {
        switch store.state.itemListCardState {
        case .passwordManagerSync:
            itemListCardSync
        case .passwordManagerDownload:
            itemListCardPasswordManagerInstall
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder private var content: some View {
        LoadingView(state: store.state.loadingState) { sections in
            if sections.isEmpty {
                emptyView
            } else {
                itemListView(with: sections)
            }
        }
    }

    /// A view that displays an empty state for this vault group.
    @ViewBuilder private var emptyView: some View {
        GeometryReader { reader in
            ScrollView {
                VStack(spacing: 16) {
                    cardSection

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
                .accessibilityIdentifier("EmptyVaultAddCodeButton")
                .padding(.horizontal, 16)
                .frame(minWidth: reader.size.width, minHeight: reader.size.height)
            }
        }
    }

    /// The Password Manager download card definition.
    private var itemListCardPasswordManagerInstall: some View {
        ItemListCardView(
            bodyText: Localizations.storeAllOfYourLoginsAndSyncVerificationCodesDirectlyWithTheAuthenticatorApp,
            buttonText: Localizations.downloadTheBitwardenApp,
            leftImage: {
                Image(decorative: Asset.Images.bwLogo)
                    .foregroundColor(Asset.Colors.primaryBitwardenLight.swiftUIColor)
                    .frame(width: 24, height: 24)
            },
            titleText: Localizations.downloadTheBitwardenApp,
            actionTapped: {
                openURL(ExternalLinksConstants.passwordManagerLink)
            },
            closeTapped: {
                Task {
                    await store.perform(.closeCard(.passwordManagerDownload))
                }
            }
        )
        .padding(.top, 16)
    }

    /// The Password Manager sync card definition.
    private var itemListCardSync: some View {
        ItemListCardView(
            bodyText: Localizations
                .allowAuthenticatorAppSyncingInSettingsToViewAllYourVerificationCodesHere,
            buttonText: Localizations.takeMeToTheAppSettings,
            leftImage: {
                Image(decorative: Asset.Images.syncArrow)
                    .foregroundColor(Asset.Colors.primaryBitwardenLight.swiftUIColor)
                    .frame(width: 24, height: 24)
            },
            secondaryButtonText: Localizations.learnMore,
            titleText: Localizations.syncWithTheBitwardenApp,
            actionTapped: {
                openURL(ExternalLinksConstants.passwordManagerSettings)
            },
            closeTapped: {
                Task {
                    await store.perform(.closeCard(.passwordManagerSync))
                }
            },
            secondaryActionTapped: {
                openURL(ExternalLinksConstants.totpSyncHelp)
            }
        )
        .padding(.top, 16)
    }

    /// A view that displays the search interface, including search results, an empty search
    /// interface, and a message indicating that no results were found.
    @ViewBuilder private var search: some View {
        if store.state.searchText.isEmpty || !store.state.searchResults.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.state.searchResults) { item in
                        buildRow(item: item, isLastInSection: store.state.searchResults.last == item)
                            .accessibilityIdentifier("ItemCell")
                    }
                }
            }
        } else {
            SearchNoResultsView()
        }
    }

    // MARK: Private Methods

    /// Build a row in the table based on an ItemListItem. This wraps the row with a Menu that
    /// presents the various long-press options.
    ///
    /// - Parameters:
    ///   - item: The item to display in the row.
    ///   - isLastInSection: `true` if the item is the last item in the section. `false` if not.
    /// - Returns: a `View` with the row configured.
    ///
    @ViewBuilder // swiftlint:disable:next function_body_length
    private func buildRow(item: ItemListItem, isLastInSection: Bool) -> some View {
        Menu {
            AsyncButton {
                await store.perform(.copyPressed(item))
            } label: {
                HStack(spacing: 4) {
                    Text(Localizations.copy)
                    Spacer()
                    Image(decorative: Asset.Images.copy)
                        .imageStyle(.accessoryIcon(scaleWithFont: true))
                }
            }

            if case .totp = item.itemType {
                Button {
                    store.send(.editPressed(item))
                } label: {
                    HStack(spacing: 4) {
                        Text(Localizations.edit)
                        Spacer()
                        Image(decorative: Asset.Images.pencil)
                            .imageStyle(.accessoryIcon(scaleWithFont: true))
                    }
                }

                if store.state.showMoveToBitwarden {
                    AsyncButton {
                        await store.perform(.moveToBitwardenPressed(item))
                    } label: {
                        HStack(spacing: 4) {
                            Text(Localizations.copyToBitwardenVault)
                            Spacer()
                            Image(decorative: Asset.Images.rightArrow)
                                .imageStyle(.accessoryIcon(scaleWithFont: true))
                        }
                    }
                }

                Divider()

                Button(role: .destructive) {
                    store.send(.deletePressed(item))
                } label: {
                    HStack(spacing: 4) {
                        Text(Localizations.delete)
                        Spacer()
                        Image(decorative: Asset.Images.trash)
                            .imageStyle(.accessoryIcon(scaleWithFont: true))
                    }
                }
            }
        } label: {
            itemListItemRow(
                for: item,
                isLastInSection: isLastInSection
            )
        } primaryAction: {
            store.send(.itemPressed(item))
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
    }

    /// A view that displays a list of the sections within this vault group.
    ///
    @ViewBuilder
    private func groupView(title: String?, items: [ItemListItem]) -> some View {
        LazyVStack(alignment: .leading, spacing: 7) {
            if let title = title?.nilIfEmpty {
                ExpandableHeaderView(title: title, count: items.count) {
                    ForEach(items) { item in
                        buildRow(item: item, isLastInSection: true)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                ForEach(items) { item in
                    if item.itemType == .syncError {
                        Text(item.name)
                            .styleGuide(.footnote)
                    } else {
                        buildRow(item: item, isLastInSection: true)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    /// A view that displays the main list of items, split into sections
    ///
    /// - Parameter sections: The sections of the vault list to display.
    @ViewBuilder
    private func itemListView(with sections: [ItemListSection]) -> some View {
        ScrollView {
            cardSection
                .padding(.horizontal, 16)

            VStack(spacing: 20) {
                ForEach(sections) { section in
                    groupView(title: section.name, items: section.items)
                }
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
    private func itemListItemRow(for item: ItemListItem, isLastInSection: Bool = false) -> some View {
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
                mapAction: nil,
                mapEffect: nil
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
        }
        .navigationTitle(Localizations.verificationCodes)
        .navigationBarTitleDisplayMode(.large)
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
struct ItemListView_Previews: PreviewProvider { // swiftlint:disable:this type_body_length
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
                                    ItemListSection(
                                        id: "Favorites",
                                        items: [
                                            ItemListItem(
                                                id: "Favorited",
                                                name: "Favorited",
                                                accountName: nil,
                                                itemType: .totp(
                                                    model: ItemListTotpItem(
                                                        itemView: .fixture(),
                                                        totpCode: TOTPCodeModel(
                                                            code: "123456",
                                                            codeGenerationDate: Date(),
                                                            period: 30
                                                        )
                                                    )
                                                )
                                            ),
                                        ],
                                        name: "Favorites"
                                    ),
                                    ItemListSection(
                                        id: "Section",
                                        items: [
                                            ItemListItem(
                                                id: "One",
                                                name: "One",
                                                accountName: nil,
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
                                                accountName: nil,
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
                                        name: "Personal"
                                    ),
                                ]
                            )
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("Items with Favorite")

        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            loadingState: .data(
                                [
                                    ItemListSection(
                                        id: "Section",
                                        items: [
                                            ItemListItem(
                                                id: "One",
                                                name: "One",
                                                accountName: nil,
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
                                                accountName: nil,
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
                                        name: ""
                                    ),
                                ]
                            )
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("Items without Favorite")

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
                                    accountName: "person@example.com",
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
                                    accountName: "person@example.com",
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
                                    accountName: nil,
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
                                    accountName: "person@example.com",
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

        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            loadingState: .data([ItemListSection.digitsFixture(accountNames: true)])
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("Digits")

        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            loadingState: .data([
                                ItemListSection.digitsFixture(accountNames: true),
                                ItemListSection(
                                    id: "",
                                    items: [.syncError()],
                                    name: ""
                                ),
                            ])
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("SyncError")

        NavigationView {
            ItemListView(
                store: Store(
                    processor: StateProcessor(
                        state: ItemListState(
                            loadingState: .data([
                                ItemListSection.digitsFixture(accountNames: true),
                                ItemListSection(
                                    id: "",
                                    items: [
                                        ItemListItem(
                                            id: "Shared One",
                                            name: "Share",
                                            accountName: "person@shared.com",
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
                                    name: "example.com",
                                ),
                            ])
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }.previewDisplayName("SharedItems")
    }
}
#endif
