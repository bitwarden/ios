import BitwardenKit
import SwiftUI

/// A unified view for registering, asserting, and managing passkeys.
///
struct PasskeyScenarioView: View {
    // MARK: Properties

    @Environment(\.openURL) private var openURL

    /// The store used to render the view.
    @ObservedObject var store: Store<PasskeyScenarioState, PasskeyScenarioAction, PasskeyScenarioEffect>

    // MARK: View

    var body: some View {
        Form {
            Section {
                Picker("", selection: store.binding(get: \.mode, send: PasskeyScenarioAction.modeChanged)) {
                    ForEach(PasskeyScenarioState.Mode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            modeContent
        }
        .navigationTitle(store.state.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(Localizations.clearAll) {
                    Task { await store.perform(.clearAll) }
                }
                .disabled(store.state.mode != .manage || store.state.passkeys.isEmpty)
            }
        }
        .task { await store.perform(.loadPasskeys) }
        .onChange(of: store.state.mode) { newMode in
            if newMode == .manage {
                Task { await store.perform(.loadPasskeys) }
            }
        }
    }

    // MARK: Private Views

    @ViewBuilder private var modeContent: some View {
        switch store.state.mode {
        case .authenticate:
            authenticateContent
        case .create:
            createContent
        case .manage:
            manageContent
        }
    }

    // MARK: Authenticate Tab

    @ViewBuilder private var authenticateContent: some View {
        Section {
            TextField(
                Localizations.relyingPartyId,
                text: store.binding(
                    get: \.rpId,
                    send: PasskeyScenarioAction.rpIdChanged,
                ),
            )
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        } footer: {
            Text(Localizations.usePasskeyFormDescriptionLong)
        }

        Section {
            Button {
                Task { await store.perform(.assertPasskey) }
            } label: {
                HStack {
                    Text(Localizations.signInWithPasskey)
                    Spacer()
                    if store.state.assertionStatus == .inProgress {
                        ProgressView()
                    }
                }
            }
            .disabled(store.state.assertionStatus == .inProgress || store.state.rpId.isEmpty)
        }

        assertionStatusSection
    }

    @ViewBuilder private var assertionStatusSection: some View {
        switch store.state.assertionStatus {
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

    // MARK: Create Tab

    @ViewBuilder private var createContent: some View {
        Section {
            TextField(
                Localizations.relyingPartyId,
                text: store.binding(
                    get: \.rpId,
                    send: PasskeyScenarioAction.rpIdChanged,
                ),
            )
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            TextField(
                Localizations.username,
                text: store.binding(
                    get: \.userName,
                    send: PasskeyScenarioAction.userNameChanged,
                ),
            )
            .textContentType(.username)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            TextField(
                Localizations.displayName,
                text: store.binding(
                    get: \.displayName,
                    send: PasskeyScenarioAction.displayNameChanged,
                ),
            )
            .textContentType(.name)
        } header: {
            Text(Localizations.credentials)
        } footer: {
            Text(Localizations.relyingPartyIdFooterDescriptionLong)
        }

        Section {
            Button {
                Task { await store.perform(.registerPasskey) }
            } label: {
                HStack {
                    Text(Localizations.registerPasskey)
                    Spacer()
                    if store.state.registrationStatus == .inProgress {
                        ProgressView()
                    }
                }
            }
            .disabled(
                store.state.registrationStatus == .inProgress
                    || store.state.rpId.isEmpty
                    || store.state.userName.isEmpty,
            )
        } footer: {
            Text(Localizations.createPasskeyFormDescriptionLong)
        }

        registrationStatusSection
    }

    @ViewBuilder private var registrationStatusSection: some View {
        switch store.state.registrationStatus {
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

    // MARK: Manage Tab

    @ViewBuilder private var manageContent: some View {
        if store.state.passkeys.isEmpty {
            Section {
                Text(Localizations.noPasskeysRegisteredDescription)
                    .styleGuide(.subheadline)
                    .foregroundColor(.secondary)
            } header: {
                Text(Localizations.registeredPasskeys)
            }
        } else {
            Section {
                ForEach(store.state.passkeys) { entry in
                    Button {
                        if let url = URL(string: "bitwarden://") {
                            openURL(url)
                        }
                    } label: {
                        passkeyRow(entry)
                    }
                    .tint(.primary)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let entry = store.state.passkeys[index]
                        Task { await store.perform(.deletePasskey(entry)) }
                    }
                }
            } header: {
                Text(Localizations.registeredPasskeys)
            } footer: {
                Text(Localizations.managePasskeysFooterNote)
            }
        }
    }

    private func passkeyRow(_ entry: PasskeyEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.userName)
                .styleGuide(.body)
            Text(entry.rpId)
                .styleGuide(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Text(entry.createdAt, style: .date)
                Text(entry.createdAt, style: .time)
            }
            .styleGuide(.caption1)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Create") {
    NavigationView {
        PasskeyScenarioView(store: Store(processor: StateProcessor(state: PasskeyScenarioState())))
    }
}

#Preview("Authenticate") {
    NavigationView {
        PasskeyScenarioView(
            store: Store(processor: StateProcessor(state: {
                var state = PasskeyScenarioState()
                state.mode = .authenticate
                return state
            }())),
        )
    }
}

#Preview("Manage — Empty") {
    NavigationView {
        PasskeyScenarioView(
            store: Store(processor: StateProcessor(state: {
                var state = PasskeyScenarioState()
                state.mode = .manage
                return state
            }())),
        )
    }
}

#Preview("Manage — With Passkeys") {
    NavigationView {
        PasskeyScenarioView(
            store: Store(processor: StateProcessor(state: {
                var state = PasskeyScenarioState()
                state.mode = .manage
                state.passkeys = [
                    PasskeyEntry(
                        id: UUID(),
                        rpId: "bitwarden.pw",
                        userName: "user@example.com",
                        displayName: "Example User",
                        createdAt: Date(),
                    ),
                    PasskeyEntry(
                        id: UUID(),
                        rpId: "bitwarden.com",
                        userName: "test@bitwarden.com",
                        displayName: "Test User",
                        createdAt: Date(),
                    ),
                ]
                return state
            }())),
        )
    }
}
#endif
