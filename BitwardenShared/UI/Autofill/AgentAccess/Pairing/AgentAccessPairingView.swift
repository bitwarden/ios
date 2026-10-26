import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - AgentAccessPairingView

/// A view that pairs a new agent with a one-time token or a short code.
///
struct AgentAccessPairingView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<AgentAccessPairingState, AgentAccessPairingAction, AgentAccessPairingEffect>

    // MARK: View

    var body: some View {
        content
            .scrollView()
            .navigationBar(title: Localizations.agentAccessPairAgent, titleDisplayMode: .inline)
            .toast(store.binding(
                get: \.toast,
                send: AgentAccessPairingAction.toastShown,
            ))
            .task(id: store.state.pairing?.token) {
                await store.perform(.streamEvents)
            }
    }

    // MARK: Private Views

    /// The content shown for the current step of the flow.
    @ViewBuilder private var content: some View {
        switch store.state.phase {
        case .form:
            form
        case .waiting:
            waiting
        case let .verifying(verification):
            verifying(verification)
        case .paired:
            statusMessage(Localizations.agentAccessPairedSuccess, identifier: "AgentAccessPairedLabel")
        case .rejected:
            retry(Localizations.agentAccessPairingRejected, identifier: "AgentAccessPairingRejectedLabel")
        case let .failed(message):
            retry(Localizations.agentAccessPairingFailed, detail: message, identifier: "AgentAccessPairingFailedLabel")
        }
    }

    /// The name field, the mode picker and the start button.
    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            BitwardenTextField(
                title: Localizations.agentAccessPairingName,
                text: store.binding(
                    get: \.connectionName,
                    send: AgentAccessPairingAction.connectionNameChanged,
                ),
                accessibilityIdentifier: "AgentAccessConnectionNameField",
            )

            BitwardenSegmentedControl(
                selection: store.binding(
                    get: \.mode,
                    send: AgentAccessPairingAction.modeChanged,
                ),
                selections: AgentAccessPairingMode.allCases,
            )

            AsyncButton(Localizations.agentAccessStartPairing) {
                await store.perform(.startPairing)
            }
            .buttonStyle(.primary())
            .disabled(!store.state.canStartPairing)
            .accessibilityIdentifier("AgentAccessStartPairingButton")
        }
    }

    /// The buttons that copy and share the token.
    private var tokenButtons: some View {
        HStack(spacing: 12) {
            Button(Localizations.agentAccessCopyToken) {
                store.send(.copyToken)
            }
            .buttonStyle(.primary())
            .accessibilityIdentifier("AgentAccessCopyTokenButton")

            Button(Localizations.agentAccessShareToken) {
                store.send(.shareToken)
            }
            .buttonStyle(.secondary())
            .accessibilityIdentifier("AgentAccessShareTokenButton")
        }
    }

    /// The token or code and the progress while the app waits for the agent.
    @ViewBuilder private var waiting: some View {
        if let pairing = store.state.pairing {
            switch pairing.kind {
            case .psk:
                tokenContent(pairing)
            case .rendezvous:
                codeContent(pairing)
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Private Methods

    /// The big code that is typed into the agent.
    ///
    /// - Parameter pairing: The rendezvous pairing.
    ///
    private func codeContent(_ pairing: AgentAccessPairing) -> some View {
        VStack(spacing: 16) {
            Text(Localizations.agentAccessCodeInstructions)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)

            Text(pairing.token)
                .styleGuide(.bodyMonospaced, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .textSelection(.enabled)
                .accessibilityIdentifier("AgentAccessCodeLabel")

            waitingFooter(pairing)
        }
        .frame(maxWidth: .infinity)
    }

    /// A message with a try again button.
    ///
    /// - Parameters:
    ///   - text: The message to show.
    ///   - detail: More detail about the problem, if any.
    ///   - identifier: The accessibility identifier of the message.
    ///
    private func retry(_ text: String, detail: String = "", identifier: String) -> some View {
        VStack(spacing: 16) {
            statusMessage(text, identifier: identifier)

            if !detail.isEmpty {
                Text(detail)
                    .styleGuide(.footnote)
                    .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .multilineTextAlignment(.center)
            }

            Button(Localizations.tryAgain) {
                store.send(.tryAgain)
            }
            .buttonStyle(.primary())
            .accessibilityIdentifier("AgentAccessTryAgainButton")
        }
    }

    /// A centered message.
    ///
    /// - Parameters:
    ///   - text: The message to show.
    ///   - identifier: The accessibility identifier of the message.
    ///
    private func statusMessage(_ text: String, identifier: String) -> some View {
        Text(text)
            .styleGuide(.body)
            .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(identifier)
    }

    /// The token, its QR code and the buttons to copy and share it.
    ///
    /// - Parameter pairing: The PSK pairing.
    ///
    private func tokenContent(_ pairing: AgentAccessPairing) -> some View {
        VStack(spacing: 16) {
            Text(Localizations.agentAccessTokenInstructions)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)

            if let image = AgentAccessQRCode.image(for: pairing.token) {
                qrCode(image)
            }

            Text(pairing.token)
                .styleGuide(.sensitiveInfoSmall)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityIdentifier("AgentAccessTokenLabel")

            tokenButtons

            if let command = store.state.exampleCommand {
                exampleCommand(command)
            }

            waitingFooter(pairing)
        }
    }

    /// The QR code of the token.
    ///
    /// - Parameter image: The rendered QR code.
    ///
    private func qrCode(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)
            .accessibilityIdentifier("AgentAccessQRCode")
    }

    /// A sample command that uses the token.
    ///
    /// - Parameter command: The command to show.
    ///
    private func exampleCommand(_ command: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localizations.agentAccessExampleCommand)
                .styleGuide(.footnote, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)

            Text(command)
                .styleGuide(.caption2Monospaced)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
                .textSelection(.enabled)
                .accessibilityIdentifier("AgentAccessExampleCommandLabel")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The comparison of the code on the phone with the one on the agent.
    ///
    /// - Parameter verification: The fingerprint comparison to answer.
    ///
    private func verifying(_ verification: AgentAccessFingerprintVerification) -> some View {
        VStack(spacing: 16) {
            Text(Localizations.agentAccessCompareFingerprint)
                .styleGuide(.body)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)

            Text(verification.code)
                .styleGuide(.bodyMonospaced, weight: .semibold)
                .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                .accessibilityIdentifier("AgentAccessFingerprintLabel")

            VStack(spacing: 12) {
                Button(Localizations.agentAccessConfirm) {
                    store.send(.confirmFingerprint)
                }
                .buttonStyle(.primary())
                .accessibilityIdentifier("AgentAccessConfirmFingerprintButton")

                Button(Localizations.agentAccessReject) {
                    store.send(.rejectFingerprint)
                }
                .buttonStyle(.secondary())
                .accessibilityIdentifier("AgentAccessRejectFingerprintButton")
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// The progress and expiry shown under a token or code.
    ///
    /// - Parameter pairing: The pairing in progress.
    ///
    private func waitingFooter(_ pairing: AgentAccessPairing) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                ProgressView()
                Text(Localizations.agentAccessWaitingForAgent)
                    .styleGuide(.body)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("AgentAccessWaitingLabel")

            Text(Localizations.agentAccessExpiresAt(pairing.expiresAt.formatted(date: .omitted, time: .shortened)))
                .styleGuide(.footnote)
                .foregroundStyle(SharedAsset.Colors.textSecondary.swiftUIColor)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Form") {
    NavigationView {
        AgentAccessPairingView(
            store: Store(processor: StateProcessor(state: AgentAccessPairingState())),
        )
    }
}

#Preview("Token") {
    NavigationView {
        AgentAccessPairingView(
            store: Store(processor: StateProcessor(state: AgentAccessPairingState(
                pairing: AgentAccessPairing(
                    kind: .psk,
                    token: String(repeating: "a", count: 64) + "_" + String(repeating: "b", count: 64),
                    name: "Codex",
                    createdAt: .now,
                    expiresAt: .now.addingTimeInterval(600),
                ),
                phase: .waiting,
            ))),
        )
    }
}

#Preview("Code") {
    NavigationView {
        AgentAccessPairingView(
            store: Store(processor: StateProcessor(state: AgentAccessPairingState(
                mode: .code,
                pairing: AgentAccessPairing(
                    kind: .rendezvous,
                    token: "ABC-DEF-GHI",
                    name: "Codex",
                    createdAt: .now,
                    expiresAt: .now.addingTimeInterval(300),
                ),
                phase: .waiting,
            ))),
        )
    }
}
#endif
