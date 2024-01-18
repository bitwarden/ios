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
        content
            .navigationBar(title: Localizations.items, titleDisplayMode: .inline)
            .scrollView()
            .task { await store.perform(.streamAutofillItems) }
            .toast(store.binding(
                get: \.toast,
                send: VaultAutofillListAction.toastShown
            ))
            .toolbar {
                addToolbarItem {
                    store.send(.addTapped)
                }

                cancelToolbarItem {
                    store.send(.cancelTapped)
                }
            }
    }

    // MARK: Private Views

    /// The content displayed in the view.
    @ViewBuilder private var content: some View {
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
        } else {
            LazyVStack(spacing: 0) {
                ForEach(store.state.ciphersForAutofill) { cipher in
                    AsyncButton {
                        await store.perform(.cipherTapped(cipher))
                    } label: {
                        cipherRowView(cipher, hasDivider: cipher != store.state.ciphersForAutofill.last)
                    }
                }
            }
            .background(Asset.Colors.backgroundPrimary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    /// Returns the view for displaying a cipher in a row in a list.
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
