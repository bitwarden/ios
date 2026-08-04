import BitwardenKit
import SwiftUI

// MARK: - SDKRegisterPasskeyView

/// A view that allows registering a passkey directly through the Bitwarden SDK, the same way
/// the main Bitwarden app and its AutoFill extension do.
///
struct SDKRegisterPasskeyView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<SDKRegisterPasskeyState, SDKRegisterPasskeyAction, SDKRegisterPasskeyEffect>

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
                    send: SDKRegisterPasskeyAction.rpIdChanged,
                ),
            )
            .accessibilityIdentifier("SDKRelyingPartyIdEntry")
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            TextField(
                Localizations.username,
                text: store.binding(
                    get: \.userName,
                    send: SDKRegisterPasskeyAction.userNameChanged,
                ),
            )
            .accessibilityIdentifier("SDKUsernameEntry")
            .textContentType(.username)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            TextField(
                Localizations.displayName,
                text: store.binding(
                    get: \.displayName,
                    send: SDKRegisterPasskeyAction.displayNameChanged,
                ),
            )
            .accessibilityIdentifier("SDKDisplayNameEntry")
            .textContentType(.name)
        } header: {
            Text(Localizations.credentials)
        } footer: {
            Text(Localizations.sdkRegisterPasskeyFormDescriptionLong)
        }
    }

    /// The section containing the button that triggers SDK-backed passkey registration.
    private var registerButtonSection: some View {
        Section {
            Button {
                Task { await store.perform(.registerPasskey) }
            } label: {
                HStack {
                    Text(Localizations.sdkRegisterPasskey)
                    Spacer()
                    if store.state.status == .inProgress {
                        ProgressView()
                    }
                }
            }
            .disabled(store.state.status == .inProgress || store.state.rpId.isEmpty || store.state.userName.isEmpty)
            .accessibilityIdentifier("SDKRegisterPasskeyButton")
        }
    }

    /// The section displaying the result of the most recent registration attempt, if any.
    @ViewBuilder private var statusSection: some View {
        switch store.state.status {
        case .idle, .inProgress:
            EmptyView()
        case let .success(credentialId):
            Section {
                Label(Localizations.sdkPasskeyRegisteredSuccessfully, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("SDKRegistrationSuccessLabel")
                Text(Localizations.xColonY(Localizations.credentialId, credentialId))
                    .font(.footnote)
            } header: {
                Text(Localizations.registrationResult)
            }
        case let .failure(message):
            Section {
                Label(message, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("SDKRegistrationFailureLabel")
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
        SDKRegisterPasskeyView(store: Store(processor: StateProcessor(state: SDKRegisterPasskeyState())))
    }
}

#Preview("Success") {
    NavigationView {
        SDKRegisterPasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = SDKRegisterPasskeyState()
                state.status = .success(credentialId: "AQIDBA==")
                return state
            }())),
        )
    }
}

#Preview("Failure") {
    NavigationView {
        SDKRegisterPasskeyView(
            store: Store(processor: StateProcessor(state: {
                var state = SDKRegisterPasskeyState()
                state.status = .failure("The SDK client could not be initialized.")
                return state
            }())),
        )
    }
}
#endif
