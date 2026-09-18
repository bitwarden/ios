import BitwardenKit
import SwiftUI

// MARK: - RegisterPasskeyView

/// A view that allows registering a passkey directly through the Bitwarden SDK, the same way
/// the main Bitwarden app and its AutoFill extension do.
///
struct RegisterPasskeyView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<RegisterPasskeyState, RegisterPasskeyAction, RegisterPasskeyEffect>

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
                    send: RegisterPasskeyAction.rpIdChanged,
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
                    send: RegisterPasskeyAction.userNameChanged,
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
                    send: RegisterPasskeyAction.displayNameChanged,
                ),
            )
            .accessibilityIdentifier("DisplayNameEntry")
            .textContentType(.name)
        } header: {
            Text(Localizations.credentials)
        } footer: {
            Text(Localizations.registerPasskeyFormDescriptionLong)
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
        }
    }

    /// The section displaying the result of the most recent registration attempt, if any.
    @ViewBuilder private var statusSection: some View {
        switch store.state.status {
        case .idle, .inProgress:
            EmptyView()
        case let .success(credentialId):
            Section {
                Label(Localizations.passkeyRegisteredSuccessfully, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("RegistrationSuccessLabel")
                Text(Localizations.xColonY(Localizations.credentialId, credentialId))
                    .font(.footnote)
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
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Idle") {
    NavigationView {
        RegisterPasskeyView(store: Store(processor: StateProcessor(state: RegisterPasskeyState())))
    }
}

#Preview("Success") {
    NavigationView {
        RegisterPasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = RegisterPasskeyState()
                state.status = .success(credentialId: "AQIDBA==")
                return state
            }())),
        )
    }
}

#Preview("Failure") {
    NavigationView {
        RegisterPasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = RegisterPasskeyState()
                state.status = .failure("The SDK client could not be initialized.")
                return state
            }())),
        )
    }
}
#endif
