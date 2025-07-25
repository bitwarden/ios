import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - VaultAutofillListView

/// A view that allows the user see a list of their vault item for autofill.
///
struct VaultAutofillListView: View {
    // MARK: Properties

    /// The GroupSearchDelegate used to bridge UIKit to SwiftUI
    var searchHandler: VaultAutofillSearchHandler?

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultAutofillListState, VaultAutofillListAction, VaultAutofillListEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

    // MARK: View

    var body: some View {
        ZStack {
            VaultAutofillListSearchableView(store: store, timeProvider: timeProvider)

            profileSwitcher
        }
        .navigationBar(title: store.state.group?.navigationTitle ?? Localizations.items, titleDisplayMode: .inline)
        .if(store.state.excludedCredentialIdFound == nil) { view in
            view.searchable(
                text: store.binding(
                    get: \.searchText,
                    send: VaultAutofillListAction.searchTextChanged
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Localizations.search
            )
        }
        .toolbar {
            cancelToolbarItem(hidden: store.state.group != nil) {
                store.send(.cancelTapped)
            }

            ToolbarItem(placement: .navigationBarLeading) {
                ProfileSwitcherToolbarView(
                    store: store.child(
                        state: \.profileSwitcherState,
                        mapAction: VaultAutofillListAction.profileSwitcher,
                        mapEffect: VaultAutofillListEffect.profileSwitcher
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
                mapAction: VaultAutofillListAction.profileSwitcher,
                mapEffect: VaultAutofillListEffect.profileSwitcher
            )
        )
    }
}

// MARK: - VaultAutofillListSearchableView

/// A view that that displays the content of `VaultAutofillListView`. This needs to be a separate
/// view from `VaultAutofillListView` to enable the `isSearching` environment variable within this
/// view.
///
private struct VaultAutofillListSearchableView: View {
    // MARK: Properties

    /// A flag indicating if the search bar is focused.
    @Environment(\.isSearching) private var isSearching

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultAutofillListState, VaultAutofillListAction, VaultAutofillListEffect>

    /// The `TimeProvider` used to calculate TOTP expiration.
    var timeProvider: any TimeProvider

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
                await store.perform(.initFido2)
            }
            .task {
                await store.perform(.streamAutofillItems)
            }
            .task {
                await store.perform(.streamShowWebIcons)
            }
            .task(id: store.state.searchText) {
                await store.perform(.search(store.state.searchText))
            }
            .task(id: store.state.excludedCredentialIdFound) {
                await store.perform(.excludedCredentialFoundChaged)
            }
            .toast(
                store.binding(
                    get: \.toast,
                    send: VaultAutofillListAction.toastShown
                ),
                additionalBottomPadding: FloatingActionButton.bottomOffsetPadding
            )
    }

    // MARK: Private Views

    /// A view for displaying a list of ciphers.
    @ViewBuilder
    private func cipherListView(_ sections: [VaultListSection]) -> some View {
        Group {
            if store.state.isAutofillingFido2List || store.state.isCreatingFido2Credential ||
                store.state.isAutofillingTextToInsertList {
                cipherCombinedListView(sections)
            } else {
                let items = sections.first?.items ?? []
                cipherSimpleListView(items)
            }
        }
        .padding(.bottom, FloatingActionButton.bottomOffsetPadding)
        .scrollView()
    }

    /// A view for displaying a list of sections with ciphers.
    @ViewBuilder
    private func cipherCombinedListView(_ sections: [VaultListSection]) -> some View {
        LazyVStack(spacing: 16) {
            ForEach(sections) { section in
                VaultListSectionView(
                    section: section,
                    showCount: !store.state.isCreatingFido2Credential
                ) { item in
                    AsyncButton {
                        await store.perform(.vaultItemTapped(item))
                    } label: {
                        vaultItemRow(for: item, isLastInSection: section.items.last == item)
                    }
                }
            }
        }
    }

    /// A view for displaying a list of ciphers without sections.
    @ViewBuilder
    private func cipherSimpleListView(_ items: [VaultListItem]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(items) { item in
                AsyncButton {
                    await store.perform(.vaultItemTapped(item))
                } label: {
                    vaultItemRow(for: item, isLastInSection: items.last == item)
                }
            }
        }
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
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
        VaultListItemRowView(
            store: store.child(
                state: { state in
                    VaultListItemRowState(
                        iconBaseURL: state.iconBaseURL,
                        isFromExtension: true,
                        item: item,
                        hasDivider: !isLastInSection,
                        showTotpCopyButton: false,
                        showWebIcons: state.showWebIcons
                    )
                },
                mapAction: nil,
                mapEffect: nil
            ),
            timeProvider: timeProvider
        )
    }

    /// The content displayed in the view.
    @ViewBuilder
    private func contentView() -> some View {
        ZStack {
            let isSearching = isSearching
                || !store.state.searchText.isEmpty
                || !store.state.ciphersForSearch.isEmpty

            Group {
                if store.state.vaultListSections.isEmpty {
                    IllustratedMessageView(
                        image: Asset.Images.Illustrations.items.swiftUIImage,
                        message: store.state.emptyViewMessage
                    ) {
                        if store.state.isAutofillingTotpList
                            || store.state.isAutofillingTextToInsertList {
                            EmptyView()
                        } else {
                            Button {
                                store.send(.addTapped(fromFAB: false))
                            } label: {
                                Label {
                                    Text(store.state.emptyViewButtonText)
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
                    }
                    .scrollView(centerContentVertically: true)
                } else {
                    cipherListView(store.state.vaultListSections)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                addItemFloatingActionButton(hidden: !store.state.showAddItemButton) {
                    store.send(.addTapped(fromFAB: true))
                }
            }
            .hidden(isSearching)

            searchContentView()
                .hidden(!isSearching)
        }
    }

    /// A view for displaying the cipher search results.
    @ViewBuilder
    private func searchContentView() -> some View {
        if store.state.showNoResults {
            SearchNoResultsView()
        } else {
            cipherListView(store.state.ciphersForSearch)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty") {
    NavigationView {
        VaultAutofillListView(
            store: Store(
                processor: StateProcessor(
                    state: VaultAutofillListState()
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}

#Preview("Searching") {
    NavigationView {
        VaultAutofillListView(
            store: Store(
                processor: StateProcessor(
                    state: VaultAutofillListState(
                        ciphersForSearch: [
                            VaultListSection(
                                id: "Passwords",
                                items: (1 ... 12).map { id in
                                    .init(
                                        cipherListView: .fixture(
                                            id: String(id),
                                            login: .fixture(),
                                            name: "Bitwarden"
                                        )
                                    )!
                                },
                                name: "Passwords"
                            ),
                        ],
                        searchText: "Test"
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}

#Preview("Logins") {
    NavigationView {
        VaultAutofillListView(
            store: Store(
                processor: StateProcessor(
                    state: VaultAutofillListState(
                        vaultListSections: [
                            VaultListSection(
                                id: "Passwords",
                                items: (1 ... 12).map { id in
                                    .init(
                                        cipherListView: .fixture(
                                            id: String(id),
                                            login: .fixture(),
                                            name: "Bitwarden"
                                        )
                                    )!
                                },
                                name: "Passwords"
                            ),
                        ]
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}

#Preview("Combined Logins") {
    NavigationView {
        VaultAutofillListView(
            store: Store(
                processor: StateProcessor(
                    state: VaultAutofillListState(
                        isAutofillingFido2List: true,
                        vaultListSections: [
                            VaultListSection(
                                id: "Passkeys for myApp.com",
                                items: [
                                    .init(cipherListView: .fixture(
                                        id: "1",
                                        login: .fixture(username: "user@bitwarden.com"),
                                        name: "Apple"
                                    ), fido2CredentialAutofillView: .fixture(
                                        rpId: "apple.com",
                                        userNameForUi: "user"
                                    ))!,
                                    .init(cipherListView: .fixture(
                                        id: "4",
                                        login: .fixture(
                                            fido2Credentials: [.fixture()],
                                            username: "user@bitwarden.com"
                                        ),
                                        name: "myApp.com"
                                    ), fido2CredentialAutofillView: .fixture(
                                        rpId: "myApp.com",
                                        userNameForUi: "user"
                                    ))!,
                                    .init(cipherListView: .fixture(
                                        id: "5",
                                        login: .fixture(
                                            fido2Credentials: [.fixture()],
                                            username: "user@test.com"
                                        ),
                                        name: "Testing something really long to see how it looks",
                                    ), fido2CredentialAutofillView: .fixture(
                                        rpId: "someApp",
                                        userNameForUi: "user"
                                    ))!,
                                ],
                                name: "Passkeys for myApp.com"
                            ),
                            VaultListSection(
                                id: "Passwords for myApp.com",
                                items: [
                                    .init(cipherListView: .fixture(
                                        id: "1",
                                        login: .fixture(
                                            username: "user@bitwarden.com"
                                        ),
                                        name: "Apple"
                                    ))!,
                                    .init(cipherListView: .fixture(
                                        id: "2",
                                        login: .fixture(
                                            username: "user@bitwarden.com"
                                        ),
                                        name: "Bitwarden",
                                    ))!,
                                    .init(cipherListView: .fixture(
                                        id: "3",
                                        name: "Company XYZ"
                                    ))!,
                                    .init(cipherListView: .fixture(
                                        id: "4",
                                        name: "Company XYZ"
                                    ))!,
                                    .init(cipherListView: .fixture(
                                        id: "5",
                                        name: "Company XYZ"
                                    ))!,
                                ],
                                name: "Passwords for myApp.com"
                            ),
                        ]
                    )
                )
            ),
            timeProvider: PreviewTimeProvider()
        )
    }
}
#endif // swiftlint:disable:this file_length
