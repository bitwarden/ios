import BitwardenKit
import SwiftUI

/// A view that lists passkeys registered via the Test Harness and allows deleting them.
///
struct ManagePasskeysView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<ManagePasskeysState, ManagePasskeysAction, ManagePasskeysEffect>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Localizations.clearAll) {
                        Task { await store.perform(.clearAll) }
                    }
                    .disabled(store.state.passkeys.isEmpty)
                }
            }
            .task { await store.perform(.loadPasskeys) }
    }

    // MARK: Private Views

    @ViewBuilder private var content: some View {
        if store.state.passkeys.isEmpty {
            emptyState
        } else {
            passkeyList
        }
    }

    private var emptyState: some View {
        List {
            Section {
                Text(Localizations.noPasskeysRegisteredDescription)
                    .styleGuide(.subheadline)
                    .foregroundColor(.secondary)
            } header: {
                Text(Localizations.registeredPasskeys)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var passkeyList: some View {
        List {
            Section {
                ForEach(store.state.passkeys) { entry in
                    passkeyRow(entry)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let entry = store.state.passkeys[index]
                        Task { await store.perform(.deletePasskey(entry)) }
                    }
                }
            } header: {
                Text(Localizations.registeredPasskeys)
            } footer: {
                Text(Localizations.managePasskeysFooterNote)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func passkeyRow(_ entry: PasskeyEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.userName)
                .styleGuide(.body)
            Text(entry.rpId)
                .styleGuide(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Text(entry.createdAt, style: .date)
                Text(entry.createdAt, style: .time)
            }
            .styleGuide(.caption1)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Empty") {
    NavigationView {
        ManagePasskeysView(store: Store(processor: StateProcessor(state: ManagePasskeysState())))
    }
}

#Preview("With Passkeys") {
    NavigationView {
        ManagePasskeysView(
            store: Store(
                processor: StateProcessor(state: {
                    var state = ManagePasskeysState()
                    state.passkeys = [
                        PasskeyEntry(
                            id: UUID(),
                            rpId: "bitwarden.pw",
                            userName: "user@example.com",
                            displayName: "Example User",
                            createdAt: Date(),
                        ),
                        PasskeyEntry(
                            id: UUID(),
                            rpId: "bitwarden.com",
                            userName: "test@bitwarden.com",
                            displayName: "Test User",
                            createdAt: Date(),
                        ),
                    ]
                    return state
                }()),
            ),
        )
    }
}
#endif
