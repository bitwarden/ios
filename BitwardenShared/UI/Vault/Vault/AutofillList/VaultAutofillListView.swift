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
                cancelToolbarItem {
                    store.send(.cancelTapped)
                }
            }
    }

    // MARK: Private Views

    /// The content displayed in the view.
    @ViewBuilder private var content: some View {
        if store.state.ciphersForAutofill.isEmpty {
            Text(Localizations.noItemsTap)
                .styleGuide(.body)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
                .padding(16)
                .frame(maxWidth: .infinity)
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
    private func cipherRowView(_ cipher: CipherListView, hasDivider: Bool) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(cipher.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.body)

                if !cipher.subTitle.isEmpty {
                    Text(cipher.subTitle)
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
                            CipherListView(
                                id: "1",
                                organizationId: nil,
                                folderId: nil,
                                collectionIds: [],
                                name: "Apple",
                                subTitle: "user@bitwarden.com",
                                type: .login,
                                favorite: false,
                                reprompt: .none,
                                edit: true,
                                viewPassword: true,
                                attachments: 0,
                                creationDate: Date(),
                                deletedDate: nil,
                                revisionDate: Date()
                            ),
                            CipherListView(
                                id: "2",
                                organizationId: nil,
                                folderId: nil,
                                collectionIds: [],
                                name: "Bitwarden",
                                subTitle: "user@bitwarden.com",
                                type: .login,
                                favorite: false,
                                reprompt: .none,
                                edit: true,
                                viewPassword: true,
                                attachments: 0,
                                creationDate: Date(),
                                deletedDate: nil,
                                revisionDate: Date()
                            ),
                            CipherListView(
                                id: "3",
                                organizationId: nil,
                                folderId: nil,
                                collectionIds: [],
                                name: "Company XYZ",
                                subTitle: "",
                                type: .login,
                                favorite: false,
                                reprompt: .none,
                                edit: true,
                                viewPassword: true,
                                attachments: 0,
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
