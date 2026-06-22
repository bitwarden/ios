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

    private var credentialsSection: some View {
        Section {
            TextField(
                Localizations.relyingPartyId,
                text: store.binding(
                    get: \.rpId,
                    send: CreatePasskeyAction.rpIdChanged,
                ),
            )
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
            .textContentType(.name)
        } header: {
            Text(Localizations.credentials)
        } footer: {
            Text(Localizations.relyingPartyIdFooterDescriptionLong)
        }
    }

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
        } footer: {
            Text(Localizations.createPasskeyFormDescriptionLong)
        }
    }

    @ViewBuilder private var statusSection: some View {
        switch store.state.status {
        case .idle, .inProgress:
            EmptyView()
        case .success:
            Section {
                Label(Localizations.passkeyRegisteredSuccessfully, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } header: {
                Text(Localizations.registrationResult)
            }
        case let .failure(message):
            Section {
                Label(message, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
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
#endif
