import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AgentAccessConnectionsView

/// A view that lists the paired agents and lets the user revoke them.
///
struct AgentAccessConnectionsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        AgentAccessConnectionsState,
        AgentAccessConnectionsAction,
        AgentAccessConnectionsEffect,
    >

    // MARK: View

    var body: some View {
        content
            .scrollView()
            .navigationBar(title: Localizations.agentAccessConnections, titleDisplayMode: .inline)
            .task {
                await store.perform(.appeared)
            }
    }

    // MARK: Private Views

    /// The list, or a message when there is nothing to list.
    @ViewBuilder private var content: some View {
        if store.state.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("AgentAccessConnectionsLoading")
        } else if store.state.connections.isEmpty {
            Text(Localizations.agentAccessConnectionsEmpty)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("AgentAccessConnectionsEmptyLabel")
        } else {
            ContentBlock(dividerLeadingPadding: 16) {
                ForEach(store.state.connections) { connection in
                    row(connection)
                }
            }
        }
    }

    // MARK: Private Methods

    /// A row for a paired agent.
    ///
    /// - Parameter connection: The connection to show.
    ///
    private func row(_ connection: AgentAccessConnection) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(connection.displayName)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .accessibilityIdentifier("AgentAccessConnectionName")

                Text(String(connection.fingerprint.prefix(8)))
                    .styleGuide(.caption2Monospaced)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)

                Text(Localizations.agentAccessPairedOn(
                    connection.pairedAt.formatted(date: .abbreviated, time: .omitted),
                ))
                .styleGuide(.footnote)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)

                Text(Localizations.agentAccessLastUsed(
                    connection.lastConnectedAt.formatted(date: .abbreviated, time: .shortened),
                ))
                .styleGuide(.footnote)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
            }
            .multilineTextAlignment(.leading)

            Spacer()

            Button(Localizations.agentAccessRevoke) {
                store.send(.revokePressed(connection))
            }
            .buttonStyle(.secondary(isDestructive: true, shouldFillWidth: false, size: .small))
            .accessibilityIdentifier("AgentAccessRevokeButton")
        }
        .padding(16)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Connections") {
    NavigationView {
        AgentAccessConnectionsView(
            store: Store(processor: StateProcessor(state: AgentAccessConnectionsState(
                connections: [
                    AgentAccessConnection(
                        fingerprint: String(repeating: "ab", count: 32),
                        name: "Codex",
                        pairedAt: .now.addingTimeInterval(-86400),
                        lastConnectedAt: .now,
                    ),
                ],
                isLoading: false,
            ))),
        )
    }
}

#Preview("Empty") {
    NavigationView {
        AgentAccessConnectionsView(
            store: Store(processor: StateProcessor(state: AgentAccessConnectionsState(isLoading: false))),
        )
    }
}
#endif
