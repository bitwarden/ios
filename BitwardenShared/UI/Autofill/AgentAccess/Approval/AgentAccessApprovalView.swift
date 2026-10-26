import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AgentAccessApprovalView

/// A view that shows an agent's request for a login and lets the user approve it with a vault
/// item, or deny it.
///
struct AgentAccessApprovalView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AgentAccessApprovalState, AgentAccessApprovalAction, AgentAccessApprovalEffect>

    // MARK: View

    var body: some View {
        content
            .scrollView()
            .navigationBar(title: Localizations.agentAccessApprovalTitle, titleDisplayMode: .inline)
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismiss)
                }
            }
            .task {
                await store.perform(.loadData)
            }
            .task(id: store.state.status) {
                await store.perform(.streamCountdown)
            }
    }

    // MARK: Private Views

    /// The content shown for the status of the request.
    @ViewBuilder private var content: some View {
        switch store.state.status {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("AgentAccessApprovalLoading")
        case .pending:
            pendingContent
        case .failed:
            statusText(Localizations.genericErrorMessage, identifier: "AgentAccessApprovalFailed")
        case .expired:
            statusText(Localizations.agentAccessExpired, identifier: "AgentAccessApprovalExpired")
        }
    }

    /// The logins the user can pick from.
    @ViewBuilder private var candidateList: some View {
        if store.state.candidates.isEmpty {
            Text(Localizations.agentAccessNoMatchingItems)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("AgentAccessNoMatchingItemsLabel")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localizations.agentAccessChooseItem)
                    .styleGuide(.footnote, weight: .semibold)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)

                ContentBlock(dividerLeadingPadding: 16) {
                    ForEach(store.state.candidates) { candidate in
                        candidateRow(candidate)
                    }
                }
            }
        }
    }

    /// The description of what the agent wants and who is asking.
    private var header: some View {
        VStack(spacing: 8) {
            Text(store.state.descriptionText)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("AgentAccessDescriptionLabel")

            Text(store.state.fingerprintPrefix)
                .styleGuide(.caption2Monospaced)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .accessibilityIdentifier("AgentAccessFingerprintLabel")

            if let seconds = store.state.secondsRemaining {
                Text(Localizations.agentAccessSecondsLeft(seconds))
                    .styleGuide(.footnote)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .accessibilityIdentifier("AgentAccessCountdownLabel")
            }
        }
    }

    /// The content shown while the request is waiting for an answer.
    private var pendingContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            candidateList

            if !store.state.candidates.isEmpty {
                rememberSection
            }

            VStack(spacing: 12) {
                if !store.state.candidates.isEmpty {
                    AsyncButton(Localizations.agentAccessApprove) {
                        await store.perform(.approve)
                    }
                    .buttonStyle(.primary())
                    .disabled(!store.state.canApprove)
                    .accessibilityIdentifier("AgentAccessApproveButton")
                }

                AsyncButton(Localizations.agentAccessDeny) {
                    await store.perform(.deny)
                }
                .buttonStyle(.secondary())
                .accessibilityIdentifier("AgentAccessDenyButton")
            }
        }
    }

    /// The toggle that remembers the approval and the length of time to remember it for.
    private var rememberSection: some View {
        ContentBlock(dividerLeadingPadding: 16) {
            BitwardenToggle(
                Localizations.agentAccessAutoApproveFor,
                isOn: store.binding(
                    get: \.isAutoApproveOn,
                    send: AgentAccessApprovalAction.autoApproveToggled,
                ),
                accessibilityIdentifier: "AgentAccessAutoApproveSwitch",
            )

            if store.state.isAutoApproveOn {
                BitwardenMenuField(
                    accessibilityIdentifier: "AgentAccessAutoApproveDurationChooser",
                    options: AgentAccessAutoApproveDuration.all,
                    selection: store.binding(
                        get: { AgentAccessAutoApproveDuration(minutes: $0.autoApproveMinutes) },
                        send: { AgentAccessApprovalAction.autoApproveMinutesChanged($0.minutes) },
                    ),
                )
            }
        }
    }

    // MARK: Private Methods

    /// A selectable row for a login.
    ///
    /// - Parameter candidate: The login to show.
    ///
    private func candidateRow(_ candidate: AgentAccessCandidate) -> some View {
        Button {
            store.send(.itemSelected(candidate.id))
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(candidate.name)
                        .styleGuide(.body)
                        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

                    if let username = candidate.username, !username.isEmpty {
                        Text(username)
                            .styleGuide(.subheadline)
                            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                    }
                }
                .multilineTextAlignment(.leading)

                Spacer()

                if store.state.selectedCipherId == candidate.id {
                    SharedAsset.Icons.checkCircle24.swiftUIImage
                        .foregroundStyle(SharedAsset.Colors.iconSecondary.swiftUIColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .accessibilityAddTraits(store.state.selectedCipherId == candidate.id ? .isSelected : [])
        .accessibilityIdentifier("AgentAccessCandidateRow")
    }

    /// A centered message for a request that can't be answered.
    ///
    /// - Parameters:
    ///   - text: The message to show.
    ///   - identifier: The accessibility identifier of the message.
    ///
    private func statusText(_ text: String, identifier: String) -> some View {
        Text(text)
            .styleGuide(.body)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(identifier)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Pending") {
    NavigationView {
        AgentAccessApprovalView(
            store: Store(processor: StateProcessor(state: AgentAccessApprovalState(
                requestId: "1",
                candidates: [
                    AgentAccessCandidate(id: "1", name: "Example", username: "user@example.com", uri: "example.com"),
                    AgentAccessCandidate(id: "2", name: "Example work", username: "work@example.com", uri: nil),
                ],
                connectionFingerprint: String(repeating: "ab", count: 32),
                connectionName: "Codex",
                query: .domain("example.com"),
                secondsRemaining: 90,
                selectedCipherId: "1",
                status: .pending,
            ))),
        )
    }
}

#Preview("Expired") {
    NavigationView {
        AgentAccessApprovalView(
            store: Store(processor: StateProcessor(state: AgentAccessApprovalState(
                requestId: "1",
                status: .expired,
            ))),
        )
    }
}
#endif
