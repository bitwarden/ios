import BitwardenKit
import SwiftUI

// MARK: - SDKUsePasskeyView

/// A view that allows asserting a passkey directly through the Bitwarden SDK, the same way the
/// main Bitwarden app and its AutoFill extension do.
///
struct SDKUsePasskeyView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<SDKUsePasskeyState, SDKUsePasskeyAction, SDKUsePasskeyEffect>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Private Views

    private var content: some View {
        Form {
            rpIdSection
            signInButtonSection
            statusSection
        }
    }

    /// The section containing the relying party ID field.
    private var rpIdSection: some View {
        Section {
            TextField(
                Localizations.relyingPartyId,
                text: store.binding(
                    get: \.rpId,
                    send: SDKUsePasskeyAction.rpIdChanged,
                ),
            )
            .accessibilityIdentifier("SDKRelyingPartyIdEntry")
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        } footer: {
            Text(Localizations.sdkUsePasskeyFormDescriptionLong)
        }
    }

    /// The section containing the button that triggers SDK-backed passkey assertion.
    private var signInButtonSection: some View {
        Section {
            Button {
                Task { await store.perform(.assertPasskey) }
            } label: {
                HStack {
                    Text(Localizations.signInWithPasskey)
                    Spacer()
                    if store.state.status == .inProgress {
                        ProgressView()
                    }
                }
            }
            .accessibilityIdentifier("SDKSignInWithPasskeyButton")
            .disabled(store.state.status == .inProgress || store.state.rpId.isEmpty)
        }
    }

    /// The section displaying the result of the most recent assertion attempt, if any.
    @ViewBuilder private var statusSection: some View {
        switch store.state.status {
        case .idle, .inProgress:
            EmptyView()
        case let .success(credentialId, userName):
            Section {
                Label(Localizations.sdkPasskeyAssertedSuccessfully, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("SDKAssertionSuccessLabel")
                if let userName {
                    Text(Localizations.xColonY(Localizations.username, userName))
                        .font(.footnote)
                }
                Text(Localizations.xColonY(Localizations.credentialId, credentialId))
                    .font(.footnote)
            } header: {
                Text(Localizations.assertionResult)
            }
        case let .failure(message):
            Section {
                Label(message, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("SDKAssertionFailureLabel")
            } header: {
                Text(Localizations.assertionResult)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Idle") {
    NavigationView {
        SDKUsePasskeyView(store: Store(processor: StateProcessor(state: SDKUsePasskeyState())))
    }
}

#Preview("Success") {
    NavigationView {
        SDKUsePasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = SDKUsePasskeyState()
                state.status = .success(credentialId: "AQIDBA==", userName: "user")
                return state
            }())),
        )
    }
}

#Preview("Failure") {
    NavigationView {
        SDKUsePasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = SDKUsePasskeyState()
                state.status = .failure("No stored credential matches this relying party ID.")
                return state
            }())),
        )
    }
}
#endif
