import BitwardenKit
import SwiftUI

/// A view that allows asserting a passkey to test the AutoFill extension's passkey sign-in flow.
///
struct UsePasskeyView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<UsePasskeyState, UsePasskeyAction, UsePasskeyEffect>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.helpSheetPresentedChanged(true))
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityIdentifier("HelpButton")
                    .accessibilityLabel(Localizations.help)
                }
            }
            .sheet(isPresented: store.binding(
                get: \.isHelpSheetPresented,
                send: UsePasskeyAction.helpSheetPresentedChanged,
            )) {
                PasskeyErrorReferenceView {
                    store.send(.helpSheetPresentedChanged(false))
                }
            }
    }

    // MARK: Private Views

    private var content: some View {
        Form {
            rpIdSection
            signInButtonSection
            statusSection
        }
    }

    private var rpIdSection: some View {
        Section {
            TextField(
                Localizations.relyingPartyId,
                text: store.binding(
                    get: \.rpId,
                    send: UsePasskeyAction.rpIdChanged,
                ),
            )
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        } footer: {
            Text(Localizations.usePasskeyFormDescriptionLong)
        }
    }

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
            .disabled(store.state.status == .inProgress || store.state.rpId.isEmpty)
        }
    }

    @ViewBuilder private var statusSection: some View {
        switch store.state.status {
        case .idle, .inProgress:
            EmptyView()
        case let .success(credential):
            Section {
                Label(Localizations.passkeyAssertedSuccessfully, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("AssertionSuccessLabel")
                Text(Localizations.xColonY(Localizations.username, credential.userName))
                    .font(.footnote)
                Text(Localizations.xColonY(Localizations.displayName, credential.displayName))
                    .font(.footnote)
                Text(Localizations.xColonY(Localizations.credentialId, credential.credentialId.base64EncodedString()))
                    .font(.footnote)
            } header: {
                Text(Localizations.assertionResult)
            }
        case let .failure(message):
            Section {
                Label(message, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("AssertionFailureLabel")
            } header: {
                Text(Localizations.assertionResult)
            }
        case let .verificationFailure(message):
            Section {
                Label(Localizations.passkeyVerificationFailed, systemImage: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("AssertionVerificationFailureLabel")
                Text(Localizations.xColonY(Localizations.error, message))
                    .font(.footnote)
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
        UsePasskeyView(store: Store(processor: StateProcessor(state: UsePasskeyState())))
    }
}

#Preview("Success") {
    NavigationView {
        UsePasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = UsePasskeyState()
                state.status = .success(credential: StoredPasskeyCredential(
                    createdAt: Date(),
                    credentialId: Data([0x01, 0x02, 0x03]),
                    displayName: "User",
                    publicKeyX963: Data(repeating: 0x04, count: 65),
                    rpId: "bitwarden.pw",
                    userName: "user",
                ))
                return state
            }())),
        )
    }
}

#Preview("Failure") {
    NavigationView {
        UsePasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = UsePasskeyState()
                state.status = .failure("No passkey found for the given relying party.")
                return state
            }())),
        )
    }
}

#Preview("Verification Failure") {
    NavigationView {
        UsePasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = UsePasskeyState()
                state.status = .verificationFailure("The assertion signature could not be verified.")
                return state
            }())),
        )
    }
}
#endif
