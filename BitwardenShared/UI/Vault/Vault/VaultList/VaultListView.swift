// swiftlint:disable file_length

import BitwardenKit
import BitwardenResources
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
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor.ignoresSafeArea())
        .toast(
            store.binding(
                get: \.toast,
                send: VaultListAction.toastShown
            ),
            additionalBottomPadding: FloatingActionButton.bottomOffsetPadding
        )
        .toastBanner(
            title: Localizations.flightRecorderOn,
            subtitle: {
                guard let log = store.state.activeFlightRecorderLog else { return "" }
                return Localizations.flightRecorderWillBeActiveUntilDescriptionLong(
                    log.formattedEndDate,
                    log.formattedEndTime
                )
            }(),
            additionalBottomPadding: FloatingActionButton.bottomOffsetPadding,
            isVisible: store.bindingAsync(
                get: \.isFlightRecorderToastBannerVisible,
                perform: { _ in .dismissFlightRecorderToastBanner }
            )
        ) {
            Button(Localizations.goToSettings) {
                store.send(.navigateToFlightRecorderSettings)
            }
        }
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
        .onChange(of: isSearching) { newValue in
            store.send(.searchStateChanged(isSearching: newValue))
        }
        .animation(.default, value: isSearching)
    }

    // MARK: Private Properties

    /// A view that displays the empty vault interface.
    @ViewBuilder private var emptyVault: some View {
        VStack(spacing: 24) {
            Group {
                importLoginsActionCard

                vaultFilterRow
            }

            Spacer()

            IllustratedMessageView(
                image: Asset.Images.Illustrations.items,
                title: Localizations.saveAndProtectYourData,
                message: Localizations
                    .theVaultProtectsMoreThanJustPasswordsStoreSecureLoginsIdsCardsAndNotesSecurelyHere
            ) {
                Button {
                    store.send(.addItemPressed(.login))
                } label: {
                    HStack {
                        Image(decorative: Asset.Images.plus16)
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(Localizations.newLogin)
                    }
                }
                .buttonStyle(.primary(shouldFillWidth: false))
                .padding(.top, 8)
            }

            Spacer()
        }
        .animation(.easeInOut, value: store.state.importLoginsSetupProgress == .setUpLater)
        .animation(.easeInOut, value: store.state.importLoginsSetupProgress == .complete)
        .scrollView(centerContentVertically: true)
    }

    /// The action card for importing login items.
    @ViewBuilder private var importLoginsActionCard: some View {
        if store.state.shouldShowImportLoginsActionCard {
            ActionCard(
                title: Localizations.importSavedLogins,
                message: Localizations.importSavedLoginsDescriptionLong,
                actionButtonState: ActionCard.ButtonState(title: Localizations.getStarted) {
                    store.send(.showImportLogins)
                },
                dismissButtonState: ActionCard.ButtonState(title: Localizations.dismiss) {
                    await store.perform(.dismissImportLoginsActionCard)
                }
            )
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
                            .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
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
        } errorView: { errorMessage in
            errorViewWithRetry(errorMessage: errorMessage)
        }
        .overlay(alignment: .bottomTrailing) {
            addVaultItemFloatingActionMenu(
                availableItemTypes: store.state.itemTypesUserCanCreate,
            ) { type in
                store.send(.addItemPressed(type))
            } addFolder: {
                store.send(.addFolder)
            }
        }
    }

    /// Displays the vault filter row if the user is a member of any.
    private var vaultFilterRow: some View {
        SearchVaultFilterRowView(
            hasDivider: false,
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

    /// A view that displays an error message and a retry button.
    ///
    /// - Parameter errorMessage: The error message to display.
    ///
    @ViewBuilder
    private func errorViewWithRetry(errorMessage: String) -> some View {
        VStack(spacing: 24) {
            Text(errorMessage)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .styleGuide(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            AsyncButton {
                await store.perform(.tryAgainTapped)
            } label: {
                Text(Localizations.tryAgain)
            }
            .buttonStyle(
                .primary(
                    shouldFillWidth: false
                )
            )
        }
        .scrollView(centerContentVertically: true)
    }

    /// A view that displays the main vault interface, including sections for groups and
    /// vault items.
    ///
    /// - Parameter sections: The sections of the vault list to display.
    ///
    @ViewBuilder
    private func vaultContents(with sections: [VaultListSection]) -> some View {
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
        .padding(.bottom, FloatingActionButton.bottomOffsetPadding)
        .scrollView()
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
                        isFromExtension: false,
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

// MARK: - VaultListView

/// A view that allows the user to view a list of the items in their vault.
///
struct VaultListView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultListState, VaultListAction, VaultListEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    /// The window scene for requesting a review.
    var windowScene: UIWindowScene?

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
            .autocorrectionDisabled(true)
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
        .navigationBar(title: store.state.navigationTitle, titleDisplayMode: .inline)
        .toolbar {
            largeNavigationTitleToolbarItem(store.state.navigationTitle)

            ToolbarItem(placement: .topBarTrailing) {
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
        }
        .task {
            await store.perform(.refreshAccountProfiles)
        }
        .task {
            await store.perform(.appeared)
        }
        .task {
            await store.perform(.streamAccountSetupProgress)
        }
        .task {
            await store.perform(.streamFlightRecorderLog)
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
        .onAppear {
            Task {
                await store.perform(.checkAppReviewEligibility)
            }
        }
        .onDisappear {
            store.send(.disappeared)
        }
        .requestReview(windowScene: windowScene, isEligible: store.state.isEligibleForAppReview) {
            store.send(.appReviewPromptShown)
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
                            loadingState: .error(
                                errorMessage: Localizations.weAreUnableToProcessYourRequestPleaseTryAgainOrContactUs
                            )
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("Error")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            importLoginsSetupProgress: .incomplete,
                            loadingState: .data([])
                        )
                    )
                ),
                timeProvider: PreviewTimeProvider()
            )
        }
        .previewDisplayName("Empty - Import Logins")

        NavigationView {
            VaultListView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultListState(
                            loadingState: .data([
                                VaultListSection(
                                    id: "1",
                                    items: [
                                        .init(cipherListView: .fixture(
                                            id: UUID().uuidString,
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example",
                                            subtitle: "email@example.com"
                                        ))!,
                                        .init(cipherListView: .fixture(
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
                                        VaultListItem(
                                            id: "25",
                                            itemType: .group(.sshKey, 4)
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
                                        .init(cipherListView: .fixture(
                                            id: UUID().uuidString,
                                            organizationId: "1",
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example",
                                            subtitle: "email@example.com"
                                        ))!,
                                        .init(cipherListView: .fixture(
                                            id: UUID().uuidString,
                                            organizationId: "1",
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example",
                                            subtitle: "email@example.com"
                                        ))!,
                                        .init(cipherListView: .fixture(
                                            id: UUID().uuidString,
                                            organizationId: "1",
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example",
                                            subtitle: "email@example.com"
                                        ))!,
                                        .init(cipherListView: .fixture(
                                            id: UUID().uuidString,
                                            organizationId: "1",
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example",
                                            subtitle: "email@example.com"
                                        ))!,
                                        .init(cipherListView: .fixture(
                                            id: UUID().uuidString,
                                            organizationId: "1",
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example",
                                            subtitle: "email@example.com"
                                        ))!,
                                        .init(cipherListView: .fixture(
                                            id: UUID().uuidString,
                                            organizationId: "1",
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example",
                                            subtitle: "email@example.com"
                                        ))!,
                                        .init(cipherListView: .fixture(
                                            id: UUID().uuidString,
                                            organizationId: "1",
                                            login: .fixture(username: "email@example.com"),
                                            name: "Example",
                                            subtitle: "email@example.com"
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
                                    userIsManagedByOrganization: false,
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
                                .init(cipherListView: .fixture(
                                    id: UUID().uuidString,
                                    login: .fixture(username: "email@example.com"),
                                    name: "Example",
                                    subtitle: "email@example.com"
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
                                .init(cipherListView: .fixture(
                                    id: UUID().uuidString,
                                    login: .fixture(username: "email@example.com"),
                                    name: "Example",
                                    subtitle: "email@example.com"
                                ))!,
                                .init(cipherListView: .fixture(
                                    id: UUID().uuidString,
                                    login: .fixture(username: "email2@example.com"),
                                    name: "Example 2",
                                    subtitle: "email2@example.com"
                                ))!,
                                .init(cipherListView: .fixture(
                                    id: UUID().uuidString,
                                    login: .fixture(username: "email3@example.com"),
                                    name: "Example 3",
                                    subtitle: "email3@example.com"
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
