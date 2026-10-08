import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// MARK: - AgentFillApprovalView

/// A view that shows an agent fill request and lets the user approve it with a vault item, or
/// deny it.
///
struct AgentFillApprovalView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AgentFillApprovalState, AgentFillApprovalAction, AgentFillApprovalEffect>

    // MARK: View

    var body: some View {
        content
            .scrollView()
            .navigationBar(title: Localizations.aiAgentFillRequest, titleDisplayMode: .inline)
            .toolbar {
                cancelToolbarItem {
                    store.send(.dismiss)
                }
            }
            .task {
                await store.perform(.loadData)
            }
    }

    // MARK: Private Views

    /// The content shown for the status of the request.
    @ViewBuilder private var content: some View {
        switch store.state.status {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("AgentFillApprovalLoading")
        case .pending:
            pendingContent
        case .failed:
            statusText(Localizations.aiAgentFillCouldNotOpen, identifier: "AgentFillApprovalFailed")
        case .handled:
            statusText(Localizations.aiAgentFillHandled, identifier: "AgentFillApprovalHandled")
        case .expired:
            statusText(Localizations.aiAgentFillExpired, identifier: "AgentFillApprovalExpired")
        }
    }

    /// The deny menu, with the reasons the user can give.
    private var denyMenu: some View {
        Menu {
            AsyncButton(Localizations.aiAgentFillDenyNoReason) {
                await store.perform(.deny(reason: nil))
            }
            AsyncButton(Localizations.aiAgentFillDenyWrongAccount) {
                await store.perform(.deny(reason: .wrongAccount))
            }
            AsyncButton(Localizations.aiAgentFillDenyNotRequested) {
                await store.perform(.deny(reason: .notRequested))
            }
        } label: {
            Text(Localizations.aiAgentFillDeny)
        }
        .buttonStyle(.secondary())
        .accessibilityIdentifier("AgentFillDenyButton")
    }

    /// The description of what the agent wants to fill.
    private var descriptionText: some View {
        Text(description)
            .styleGuide(.body)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("AgentFillDescriptionLabel")
    }

    /// The items the user can pick from.
    @ViewBuilder private var itemList: some View {
        if store.state.items.isEmpty {
            Text(Localizations.aiAgentFillNoMatchingItems)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("AgentFillNoMatchingItemsLabel")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localizations.aiAgentFillChooseItem)
                    .styleGuide(.footnote, weight: .semibold)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)

                ContentBlock(dividerLeadingPadding: 16) {
                    ForEach(store.state.items) { item in
                        itemRow(item)
                    }
                }
            }
        }
    }

    /// The content shown while the request is waiting for an answer.
    private var pendingContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            descriptionText

            itemList

            VStack(spacing: 12) {
                AsyncButton(Localizations.aiAgentFillApprove) {
                    await store.perform(.approve)
                }
                .buttonStyle(.primary())
                .disabled(!store.state.canApprove)
                .accessibilityIdentifier("AgentFillApproveButton")

                denyMenu
            }
        }
    }

    // MARK: Private Properties

    /// The localized description of the request.
    private var description: String {
        switch store.state.cipherType {
        case .login:
            Localizations.aiAgentFillLoginDescription(
                store.state.connectionName,
                store.state.domain,
                store.state.browserName,
            )
        case .card:
            Localizations.aiAgentFillCardDescription(
                store.state.connectionName,
                store.state.domain,
                store.state.browserName,
            )
        }
    }

    // MARK: Private Methods

    /// A selectable row for an item.
    ///
    /// - Parameter item: The item to show.
    ///
    private func itemRow(_ item: AgentFillApprovalItem) -> some View {
        Button {
            store.send(.itemSelected(item.id))
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.name)
                        .styleGuide(.body)
                        .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)

                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .styleGuide(.subheadline)
                            .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                    }
                }
                .multilineTextAlignment(.leading)

                Spacer()

                if store.state.selectedItemId == item.id {
                    SharedAsset.Icons.checkCircle24.swiftUIImage
                        .foregroundStyle(SharedAsset.Colors.iconSecondary.swiftUIColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .accessibilityAddTraits(store.state.selectedItemId == item.id ? .isSelected : [])
        .accessibilityIdentifier("AgentFillItemRow")
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
#Preview("Login") {
    NavigationView {
        AgentFillApprovalView(
            store: Store(processor: StateProcessor(state: AgentFillApprovalState(
                approvalId: "1",
                browserName: "Chrome",
                connectionName: "Claude Desktop",
                domain: "delta.com",
                items: [
                    AgentFillApprovalItem(id: "1", name: "Delta", subtitle: "user@example.com"),
                    AgentFillApprovalItem(id: "2", name: "Delta (work)", subtitle: "work@example.com"),
                ],
                selectedItemId: "1",
                status: .pending,
            ))),
        )
    }
}

#Preview("Handled") {
    NavigationView {
        AgentFillApprovalView(
            store: Store(processor: StateProcessor(state: AgentFillApprovalState(
                approvalId: "1",
                status: .handled,
            ))),
        )
    }
}
#endif
