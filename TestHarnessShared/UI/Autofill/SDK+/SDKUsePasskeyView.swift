import BitwardenKit
import BitwardenSdk
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
            .task {
                await store.perform(.loadRegisteredCredentials)
            }
    }

    // MARK: Private Views

    private var content: some View {
        Form {
            registeredCredentialsSection
            statusSection
        }
    }

    /// The section listing the credentials registered so far, across app launches, or an
    /// empty-state message when none have been registered yet.
    private var registeredCredentialsSection: some View {
        Section {
            if store.state.registeredCredentials.isEmpty {
                Text(Localizations.sdkNoRegisteredCredentials)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.state.registeredCredentials, id: \.credentialId) { credential in
                    Button {
                        Task { await store.perform(.selectCredential(credential)) }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(credential.rpId)
                            if let userName = credential.userNameForUi {
                                Text(userName)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Text(
                                Localizations.xColonY(
                                    Localizations.credentialId,
                                    credential.credentialId.asHexString(),
                                ),
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            Text(Localizations.xColonY(Localizations.cipherId, credential.cipherId))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(Localizations.xColonY(Localizations.userHandle, credential.userHandle.asHexString()))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if credential.hasCounter {
                                Text(Localizations.usesSignatureCounter)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityIdentifier(
                        "SDKRegisteredCredentialRow_\(credential.rpId)_\(credential.credentialId.asHexString())",
                    )
                    .disabled(store.state.status == .inProgress)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await store.perform(.deleteCredential(credential)) }
                        } label: {
                            Label(Localizations.delete, systemImage: "trash")
                        }
                        .accessibilityIdentifier(
                            "SDKDeleteCredentialButton_\(credential.rpId)_\(credential.credentialId.asHexString())",
                        )
                    }
                }
            }
        } header: {
            Text(Localizations.sdkRegisteredCredentials)
        } footer: {
            Text(Localizations.sdkRegisteredCredentialsFooterDescriptionLong)
        }
    }

    /// The section displaying the result of the most recent assertion attempt, if any.
    @ViewBuilder private var statusSection: some View {
        switch store.state.status {
        case .idle, .inProgress:
            EmptyView()
        case let .success(credentialId, rpId, userName):
            Section {
                Label(Localizations.sdkPasskeyAssertedSuccessfully, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("SDKAssertionSuccessLabel")
                Text(Localizations.xColonY(Localizations.relyingPartyId, rpId))
                    .font(.footnote)
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
                state.status = .success(credentialId: "AQIDBA==", rpId: "bitwarden.com", userName: "user")
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

#Preview("Registered Credentials") {
    NavigationView {
        SDKUsePasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = SDKUsePasskeyState()
                state.registeredCredentials = [
                    Fido2CredentialAutofillView(
                        credentialId: Data([0x01]),
                        cipherId: "cipher-id",
                        rpId: "bitwarden.com",
                        userNameForUi: "user@example.com",
                        userHandle: Data([0x02]),
                        hasCounter: false,
                    ),
                ]
                return state
            }())),
        )
    }
}
#endif
