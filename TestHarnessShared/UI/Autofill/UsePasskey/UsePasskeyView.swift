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
            Text(Localizations.usePasskeyFormDescription)
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
        case .success:
            Section {
                Label(Localizations.passkeyAssertedSuccessfully, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } header: {
                Text(Localizations.assertionResult)
            }
        case let .failure(message):
            Section {
                Label(message, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
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
                state.status = .success
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
#endif
