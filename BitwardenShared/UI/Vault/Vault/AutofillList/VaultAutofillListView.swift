import BitwardenSdk
import SwiftUI

// MARK: - VaultAutofillListView

/// A view that allows the user see a list of their vault item for autofill.
///
struct VaultAutofillListView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultAutofillListState, VaultAutofillListAction, VaultAutofillListEffect>

    // MARK: View

    var body: some View {
        ZStack {
            VaultAutofillListSearchableView(store: store)

            profileSwitcher
        }
        .navigationBar(title: Localizations.items, titleDisplayMode: .inline)
        .searchable(
            text: store.binding(
                get: \.searchText,
                send: VaultAutofillListAction.searchTextChanged
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
                        mapAction: VaultAutofillListAction.profileSwitcher,
                        mapEffect: VaultAutofillListEffect.profileSwitcher
                    )
                )
            }

            addToolbarItem {
                store.send(.addTapped(fromToolbar: true))
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
            .toast(store.binding(
                get: \.toast,
                send: VaultAutofillListAction.toastShown
            ))
    }

    // MARK: Private Views

    /// A view for displaying a list of ciphers.
    @ViewBuilder
    private func cipherListView(_ sections: [VaultListSection]) -> some View {
        if store.state.isAutofillingFido2List || store.state.isCreatingFido2Credential {
            cipherCombinedListView(sections)
        } else {
            let items = sections.first?.items ?? []
            cipherSimpleListView(items)
        }
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
        .scrollView()
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
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                        item: item,
                        hasDivider: !isLastInSection,
                        showWebIcons: state.showWebIcons,
                        isFromExtension: true
                    )
                },
                mapAction: nil,
                mapEffect: nil
            ),
            timeProvider: nil
        )
        .accessibilityIdentifier("CipherCell")
    }

    /// The content displayed in the view.
    @ViewBuilder
    private func contentView() -> some View {
        if isSearching {
            searchContentView()
        } else {
            if store.state.vaultListSections.isEmpty {
                EmptyContentView(
                    image: Asset.Images.openSource.swiftUIImage,
                    text: store.state.emptyViewMessage
                ) {
                    Button {
                        store.send(.addTapped(fromToolbar: false))
                    } label: {
                        Label {
                            Text(store.state.emptyViewButtonText)
                        } icon: {
                            Asset.Images.plus.swiftUIImage
                                .imageStyle(.accessoryIcon(
                                    color: Asset.Colors.textPrimaryInverted.swiftUIColor,
                                    scaleWithFont: true
                                ))
                        }
                    }
                }
            } else {
                cipherListView(store.state.vaultListSections)
            }
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
        VaultAutofillListView(store: Store(processor: StateProcessor(state: VaultAutofillListState())))
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
                                items: [
                                    .init(cipherView: .fixture(
                                        id: "1",
                                        login: .fixture(username: "user@bitwarden.com"),
                                        name: "Apple"
                                    ))!,
                                    .init(cipherView: .fixture(
                                        id: "2",
                                        login: .fixture(username: "user@bitwarden.com"),
                                        name: "Bitwarden"
                                    ))!,
                                    .init(cipherView: .fixture(
                                        id: "3",
                                        name: "Company XYZ"
                                    ))!,
                                ],
                                name: "Passwords"
                            ),
                        ]
                    )
                )
            )
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
                                    .init(cipherView: .fixture(
                                        id: "1",
                                        login: .fixture(username: "user@bitwarden.com"),
                                        name: "Apple"
                                    ), fido2CredentialAutofillView: .fixture(
                                        rpId: "apple.com",
                                        userNameForUi: "user"
                                    ))!,
                                    .init(cipherView: .fixture(
                                        id: "4",
                                        login: .fixture(
                                            fido2Credentials: [
                                                .fixture(),
                                            ],
                                            username: "user@bitwarden.com"
                                        ),
                                        name: "myApp.com"
                                    ), fido2CredentialAutofillView: .fixture(
                                        rpId: "myApp.com",
                                        userNameForUi: "user"
                                    ))!,
                                    .init(cipherView: .fixture(
                                        id: "5",
                                        login: .fixture(
                                            fido2Credentials: [
                                                .fixture(),
                                            ],
                                            username: "user@test.com"
                                        ),
                                        name: "Testing something really long to see how it looks"
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
                                    .init(cipherView: .fixture(
                                        id: "1",
                                        login: .fixture(username: "user@bitwarden.com"),
                                        name: "Apple"
                                    ))!,
                                    .init(cipherView: .fixture(
                                        id: "2",
                                        login: .fixture(username: "user@bitwarden.com"),
                                        name: "Bitwarden"
                                    ))!,
                                    .init(cipherView: .fixture(
                                        id: "3",
                                        name: "Company XYZ"
                                    ))!,
                                ],
                                name: "Passwords for myApp.com"
                            ),
                        ]
                    )
                )
            )
        )
    }
}
#endif
