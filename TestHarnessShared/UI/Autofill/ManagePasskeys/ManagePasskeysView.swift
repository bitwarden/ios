import BitwardenKit
import SwiftUI

/// A view that lists passkey credentials stored by other Test Harness passkey scenarios, and
/// allows deleting them to clean up test data.
///
struct ManagePasskeysView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<ManagePasskeysState, Void, ManagePasskeysEffect>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Localizations.deleteAll, role: .destructive) {
                        Task { await store.perform(.deleteAll) }
                    }
                    .accessibilityIdentifier("DeleteAllButton")
                    .disabled(store.state.credentials.isEmpty)
                }
            }
            .task {
                await store.perform(.loadCredentials)
            }
    }

    // MARK: Private Views

    /// The main content view.
    @ViewBuilder private var content: some View {
        if store.state.credentials.isEmpty {
            emptyState
        } else {
            credentialsList
        }
    }

    /// The list of stored passkey credentials, each deletable via a swipe action.
    private var credentialsList: some View {
        List {
            ForEach(store.state.credentials) { credential in
                credentialRow(credential)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await store.perform(.deleteCredential(id: credential.id)) }
                        } label: {
                            Label(Localizations.delete, systemImage: "trash")
                        }
                        .accessibilityIdentifier("DeleteCredentialButton_\(credential.id)")
                    }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// The message shown when there are no stored passkey credentials.
    private var emptyState: some View {
        Text(Localizations.noPasskeysStored)
            .foregroundColor(.secondary)
            .accessibilityIdentifier("ManagePasskeysEmptyStateLabel")
    }

    /// A row displaying the metadata for a single stored passkey credential.
    private func credentialRow(_ credential: StoredPasskeyCredential) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localizations.xColonY(Localizations.relyingPartyId, credential.rpId))
            Text(Localizations.xColonY(Localizations.username, credential.userName))
            Text(Localizations.xColonY(Localizations.displayName, credential.displayName))
            Text(Localizations.xColonY(Localizations.createdAt, credential.createdAt.formatted()))
        }
        .font(.footnote)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty") {
    NavigationView {
        ManagePasskeysView(store: Store(processor: StateProcessor(state: ManagePasskeysState())))
    }
}

#Preview("Populated") {
    NavigationView {
        ManagePasskeysView(
            store: Store(processor: StateProcessor(state: {
                var state = ManagePasskeysState()
                state.credentials = [
                    StoredPasskeyCredential(
                        createdAt: Date(),
                        credentialId: Data([0x01, 0x02, 0x03]),
                        displayName: "User One",
                        publicKeyX963: Data(repeating: 0x04, count: 65),
                        rpId: "bitwarden.pw",
                        userName: "user1",
                    ),
                    StoredPasskeyCredential(
                        createdAt: Date(timeIntervalSinceNow: -86400),
                        credentialId: Data([0x05, 0x06, 0x07]),
                        displayName: "User Two",
                        publicKeyX963: Data(repeating: 0x08, count: 65),
                        rpId: "bitwarden.com",
                        userName: "user2",
                    ),
                ]
                return state
            }())),
        )
    }
}
#endif
