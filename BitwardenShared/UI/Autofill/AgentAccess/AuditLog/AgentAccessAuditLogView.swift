import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AgentAccessAuditLogView

/// A view that lists what agents did, newest first.
///
struct AgentAccessAuditLogView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<
        AgentAccessAuditLogState,
        AgentAccessAuditLogAction,
        AgentAccessAuditLogEffect,
    >

    // MARK: View

    var body: some View {
        content
            .scrollView()
            .navigationBar(title: Localizations.agentAccessAuditLog, titleDisplayMode: .inline)
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
                .accessibilityIdentifier("AgentAccessAuditLogLoading")
        } else if store.state.entries.isEmpty {
            Text(Localizations.agentAccessAuditEmpty)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("AgentAccessAuditEmptyLabel")
        } else {
            VStack(spacing: 16) {
                ContentBlock(dividerLeadingPadding: 16) {
                    ForEach(store.state.entries) { entry in
                        row(entry)
                    }
                }

                Button(Localizations.agentAccessAuditClear) {
                    store.send(.clearPressed)
                }
                .buttonStyle(.secondary(isDestructive: true))
                .accessibilityIdentifier("AgentAccessAuditClearButton")
            }
        }
    }

    // MARK: Private Methods

    /// A row for an activity entry.
    ///
    /// - Parameter entry: The entry to show.
    ///
    private func row(_ entry: AgentAccessAuditEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.kind.localizedName)
                .styleGuide(.body, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier("AgentAccessAuditKind")

            Text(entry.connectionName ?? String(entry.connectionFingerprint.prefix(8)))
                .styleGuide(.subheadline)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

            if let query = entry.query {
                Text(query.displayValue)
                    .styleGuide(.subheadline)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
            }

            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                .styleGuide(.footnote)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
        }
        .multilineTextAlignment(.leading)
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Activity") {
    NavigationView {
        AgentAccessAuditLogView(
            store: Store(processor: StateProcessor(state: AgentAccessAuditLogState(
                entries: [
                    AgentAccessAuditEntry(
                        id: UUID(),
                        date: .now,
                        kind: .credentialApproved,
                        connectionFingerprint: String(repeating: "ab", count: 32),
                        connectionName: "Codex",
                        query: .domain("example.com"),
                        cipherId: "cipher-1",
                    ),
                    AgentAccessAuditEntry(
                        id: UUID(),
                        date: .now.addingTimeInterval(-3600),
                        kind: .connectionEstablished,
                        connectionFingerprint: String(repeating: "ab", count: 32),
                        connectionName: "Codex",
                        query: nil,
                        cipherId: nil,
                    ),
                ],
                isLoading: false,
            ))),
        )
    }
}

#Preview("Empty") {
    NavigationView {
        AgentAccessAuditLogView(
            store: Store(processor: StateProcessor(state: AgentAccessAuditLogState(isLoading: false))),
        )
    }
}
#endif
