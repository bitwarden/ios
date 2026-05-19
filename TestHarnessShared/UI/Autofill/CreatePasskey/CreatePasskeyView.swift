import BitwardenKit
import SwiftUI

/// A view that allows registering a passkey to test the AutoFill extension's passkey creation flow.
///
struct CreatePasskeyView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<CreatePasskeyState, CreatePasskeyAction, CreatePasskeyEffect>

    // MARK: View

    var body: some View {
        content
            .navigationTitle(store.state.title)
            .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Private Views

    private var content: some View {
        Form {
            credentialsSection
            registerButtonSection
            statusSection
        }
    }

    /// The section containing the relying party ID, username, and display name fields.
    private var credentialsSection: some View {
        Section {
            TextField(
                Localizations.relyingPartyId,
                text: store.binding(
                    get: \.rpId,
                    send: CreatePasskeyAction.rpIdChanged,
                ),
            )
            .accessibilityIdentifier("RelyingPartyIdEntry")
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            TextField(
                Localizations.username,
                text: store.binding(
                    get: \.userName,
                    send: CreatePasskeyAction.userNameChanged,
                ),
            )
            .accessibilityIdentifier("UsernameEntry")
            .textContentType(.username)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            TextField(
                Localizations.displayName,
                text: store.binding(
                    get: \.displayName,
                    send: CreatePasskeyAction.displayNameChanged,
                ),
            )
            .accessibilityIdentifier("DisplayNameEntry")
            .textContentType(.name)
        } header: {
            Text(Localizations.credentials)
        } footer: {
            Text(Localizations.relyingPartyIdFooter)
        }
    }

    /// The section containing the button that triggers passkey registration.
    private var registerButtonSection: some View {
        Section {
            Button {
                Task { await store.perform(.registerPasskey) }
            } label: {
                HStack {
                    Text(Localizations.registerPasskey)
                    Spacer()
                    if store.state.status == .inProgress {
                        ProgressView()
                    }
                }
            }
            .disabled(store.state.status == .inProgress || store.state.rpId.isEmpty || store.state.userName.isEmpty)
            .accessibilityIdentifier("RegisterPasskeyButton")
        } footer: {
            Text(Localizations.createPasskeyFormDescriptionLong)
        }
    }

    /// The section displaying the result of the most recent registration attempt, if any.
    @ViewBuilder private var statusSection: some View {
        switch store.state.status {
        case .idle, .inProgress:
            EmptyView()
        case .success:
            Section {
                Label(Localizations.passkeyRegisteredSuccessfully, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("RegistrationSuccessLabel")
            } header: {
                Text(Localizations.registrationResult)
            }
        case let .failure(message):
            Section {
                Label(message, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("RegistrationFailureLabel")
            } header: {
                Text(Localizations.registrationResult)
            }
        case let .persistenceFailure(credential, message):
            Section {
                Label(Localizations.passkeyCreatedButNotSaved, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("RegistrationPersistenceFailureLabel")
                Text(Localizations.xColonY(Localizations.credentialId, credential.credentialId.base64EncodedString()))
                    .font(.footnote)
                Text(Localizations.xColonY(Localizations.error, message))
                    .font(.footnote)
            } header: {
                Text(Localizations.registrationResult)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Idle") {
    NavigationView {
        CreatePasskeyView(store: Store(processor: StateProcessor(state: CreatePasskeyState())))
    }
}

#Preview("Success") {
    NavigationView {
        CreatePasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = CreatePasskeyState()
                state.status = .success
                return state
            }())),
        )
    }
}

#Preview("Failure") {
    NavigationView {
        CreatePasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = CreatePasskeyState()
                state.status = .failure("Associated domain not configured in entitlements.")
                return state
            }())),
        )
    }
}

#Preview("Persistence Failure") {
    NavigationView {
        CreatePasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = CreatePasskeyState()
                state.status = .persistenceFailure(
                    credential: StoredPasskeyCredential(
                        createdAt: Date(),
                        credentialId: Data([0x01, 0x02, 0x03]),
                        displayName: "User",
                        publicKeyX963: Data(repeating: 0x04, count: 65),
                        rpId: "bitwarden.com",
                        userName: "user",
                    ),
                    message: "The disk is full.",
                )
                return state
            }())),
        )
    }
}
#endif
