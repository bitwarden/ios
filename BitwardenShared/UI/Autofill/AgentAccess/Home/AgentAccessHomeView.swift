import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AgentAccessHomeView

/// A view that lets the user turn on Agent Access, pair agents and review what agents did.
///
struct AgentAccessHomeView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AgentAccessHomeState, AgentAccessHomeAction, AgentAccessHomeEffect>

    // MARK: View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            listeningSection

            navigationSection

            relayServerSection

            if !store.state.autoApproveRules.isEmpty {
                autoApproveSection
            }

            Text(Localizations.agentAccessPrivacyFooter)
                .styleGuide(.footnote)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .padding(.horizontal, 16)
                .accessibilityIdentifier("AgentAccessPrivacyFooter")
        }
        .scrollView()
        .navigationBar(title: Localizations.agentAccess, titleDisplayMode: .inline)
        .task {
            await store.perform(.appeared)
        }
        .task {
            await store.perform(.streamStatus)
        }
    }

    // MARK: Private Views

    /// The chevron shown in the navigation rows.
    private var chevron: some View {
        Image(asset: SharedAsset.Icons.chevronRight16)
            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
    }

    /// The toggle and the connection status.
    private var listeningSection: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            BitwardenToggle(
                Localizations.agentAccessAllowRequests,
                isOn: store.bindingAsync(
                    get: \.isListeningEnabled,
                    perform: AgentAccessHomeEffect.setListening,
                ),
                accessibilityIdentifier: "AgentAccessAllowRequestsSwitch",
            )

            HStack {
                Text(Localizations.agentAccessStatus)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

                Spacer()

                Text(store.state.statusText)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .accessibilityIdentifier("AgentAccessStatusLabel")
            }
            .padding(16)
            .accessibilityElement(children: .combine)
        }
    }

    /// The rows that open the other Agent Access screens.
    private var navigationSection: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            SettingsListItem(Localizations.agentAccessPairAgent) {
                store.send(.pairPressed)
            } trailingContent: {
                chevron
            }
            .accessibilityIdentifier("AgentAccessPairButton")

            SettingsListItem(Localizations.agentAccessConnections) {
                store.send(.connectionsPressed)
            } trailingContent: {
                HStack(spacing: 8) {
                    Text("\(store.state.connectionsCount)")
                    chevron
                }
            }
            .accessibilityIdentifier("AgentAccessConnectionsButton")

            SettingsListItem(Localizations.agentAccessAuditLog) {
                store.send(.auditLogPressed)
            } trailingContent: {
                chevron
            }
            .accessibilityIdentifier("AgentAccessAuditLogButton")
        }
    }

    /// The relay server field and its save button.
    private var relayServerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            BitwardenTextField(
                title: Localizations.agentAccessRelayServer,
                text: store.binding(
                    get: \.relayURLInput,
                    send: AgentAccessHomeAction.relayURLChanged,
                ),
                accessibilityIdentifier: "AgentAccessRelayURLField",
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.URL)

            if let message = store.state.relayURLErrorMessage {
                Text(message)
                    .styleGuide(.footnote)
                    .foregroundStyle(SharedAsset.Colors.error.swiftUIColor)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("AgentAccessRelayURLError")
            }

            if store.state.isRelayURLChanged {
                AsyncButton(Localizations.save) {
                    await store.perform(.saveRelayURL)
                }
                .buttonStyle(.secondary())
                .accessibilityIdentifier("AgentAccessSaveRelayURLButton")
            }
        }
    }

    /// The active automatic approvals.
    private var autoApproveSection: some View {
        SectionView(Localizations.agentAccessAutoApproveRules) {
            ContentBlock(dividerLeadingPadding: 16) {
                ForEach(store.state.autoApproveRules) { rule in
                    ruleRow(rule)
                }
            }
        }
    }

    // MARK: Private Methods

    /// A row for an active automatic approval.
    ///
    /// - Parameter rule: The rule to show.
    ///
    private func ruleRow(_ rule: AgentAccessAutoApproveRule) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(rule.connectionName)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

                Text(rule.query.displayValue)
                    .styleGuide(.subheadline)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)

                Text(Localizations.agentAccessRuleUntil(rule.expiresAt.formatted(date: .omitted, time: .shortened)))
                    .styleGuide(.footnote)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
            }
            .multilineTextAlignment(.leading)

            Spacer()

            AsyncButton(Localizations.agentAccessAutoApproveRemove) {
                await store.perform(.removeRule(id: rule.id))
            }
            .buttonStyle(.secondary(shouldFillWidth: false, size: .small))
            .accessibilityIdentifier("AgentAccessRemoveRuleButton")
        }
        .padding(16)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Listening") {
    NavigationView {
        AgentAccessHomeView(
            store: Store(processor: StateProcessor(state: AgentAccessHomeState(
                autoApproveRules: [
                    AgentAccessAutoApproveRule(
                        id: "1",
                        connectionFingerprint: String(repeating: "a", count: 64),
                        connectionName: "Codex",
                        query: .domain("example.com"),
                        cipherId: "cipher-1",
                        expiresAt: .now.addingTimeInterval(600),
                    ),
                ],
                connectionsCount: 2,
                isListeningEnabled: true,
                relayURL: AgentAccessConstants.defaultRelayURL,
                relayURLInput: AgentAccessConstants.defaultRelayURL,
                status: .listening,
            ))),
        )
    }
}

#Preview("Off") {
    NavigationView {
        AgentAccessHomeView(
            store: Store(processor: StateProcessor(state: AgentAccessHomeState())),
        )
    }
}
#endif
