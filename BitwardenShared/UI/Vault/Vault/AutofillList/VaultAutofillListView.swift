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
                mapEffect: nil
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
    private func cipherListView(_ ciphers: [CipherView]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(ciphers) { cipher in
                AsyncButton {
                    await store.perform(.cipherTapped(cipher))
                } label: {
                    cipherRowView(cipher, hasDivider: cipher != ciphers.last)
                }
            }
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .scrollView()
    }

    /// A view for displaying a cipher in a row in a list.
    @ViewBuilder
    private func cipherRowView(_ cipher: CipherView, hasDivider: Bool) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(cipher.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.body)

                if let username = cipher.login?.username, !username.isEmpty {
                    Text(username)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .styleGuide(.subheadline)
                }
            }
            .lineLimit(1)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 60)

            if hasDivider {
                Divider()
                    .padding(.leading, 16)
            }
        }
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
                            CipherView(
                                id: "1",
                                organizationId: nil,
                                folderId: nil,
                                collectionIds: [],
                                key: nil,
                                name: "Apple",
                                notes: nil,
                                type: .login,
                                login: BitwardenSdk.LoginView(
                                    username: "user@bitwarden.com",
                                    password: nil,
                                    passwordRevisionDate: nil,
                                    uris: nil,
                                    totp: nil,
                                    autofillOnPageLoad: nil
                                ),
                                identity: nil,
                                card: nil,
                                secureNote: nil,
                                favorite: false,
                                reprompt: .none,
                                organizationUseTotp: false,
                                edit: true,
                                viewPassword: true,
                                localData: nil,
                                attachments: nil,
                                fields: nil,
                                passwordHistory: nil,
                                creationDate: Date(),
                                deletedDate: nil,
                                revisionDate: Date()
                            ),
                            CipherView(
                                id: "2",
                                organizationId: nil,
                                folderId: nil,
                                collectionIds: [],
                                key: nil,
                                name: "Bitwarden",
                                notes: nil,
                                type: .login,
                                login: BitwardenSdk.LoginView(
                                    username: "user@bitwarden.com",
                                    password: nil,
                                    passwordRevisionDate: nil,
                                    uris: nil,
                                    totp: nil,
                                    autofillOnPageLoad: nil
                                ),
                                identity: nil,
                                card: nil,
                                secureNote: nil,
                                favorite: false,
                                reprompt: .none,
                                organizationUseTotp: false,
                                edit: true,
                                viewPassword: true,
                                localData: nil,
                                attachments: nil,
                                fields: nil,
                                passwordHistory: nil,
                                creationDate: Date(),
                                deletedDate: nil,
                                revisionDate: Date()
                            ),
                            CipherView(
                                id: "3",
                                organizationId: nil,
                                folderId: nil,
                                collectionIds: [],
                                key: nil,
                                name: "Company XYZ",
                                notes: nil,
                                type: .login,
                                login: nil,
                                identity: nil,
                                card: nil,
                                secureNote: nil,
                                favorite: false,
                                reprompt: .none,
                                organizationUseTotp: false,
                                edit: true,
                                viewPassword: true,
                                localData: nil,
                                attachments: nil,
                                fields: nil,
                                passwordHistory: nil,
                                creationDate: Date(),
                                deletedDate: nil,
                                revisionDate: Date()
                            ),
                        ]
                    )
                )
            )
        )
    }
}
