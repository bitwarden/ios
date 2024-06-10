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
            ToolbarItem(placement: .navigationBarLeading) {
                ProfileSwitcherToolbarView(
                    store: store.child(
                        state: \.profileSwitcherState,
                        mapAction: VaultAutofillListAction.profileSwitcher,
                        mapEffect: nil
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
                await store.perform(.streamAutofillItems)
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
    private func cipherListView(_ items: [VaultListItem]) -> some View {
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
            if store.state.ciphersForAutofill.isEmpty {
                Button {
                    store.send(.addTapped)
                } label: {
                    Text(Localizations.noItemsTap)
                        .styleGuide(.body)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                }
                .scrollView()
            } else {
                cipherListView(store.state.ciphersForAutofill)
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
                        ciphersForAutofill: [
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
                            .init(cipherView: .fixture(
                                id: "3",
                                login: .fixture(
                                    fido2Credentials: [
                                        .fixture(rpId: "someApp", userName: "user"),
                                    ],
                                    username: "user@bitwarden.com"
                                ),
                                name: "Company XYZ"
                            ), asFido2Credential: true)!,
                        ]
                    )
                )
            )
        )
    }
}
#endif
