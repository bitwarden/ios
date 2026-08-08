import BitwardenKit

// MARK: - ManagePasskeysProcessor

/// The processor for the manage passkeys test screen.
///
class ManagePasskeysProcessor: StateProcessor<
    ManagePasskeysState,
    Void,
    ManagePasskeysEffect,
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    // MARK: Internal for Testability

    /// Reads, deletes, and clears previously created passkey credentials. Defaults to a
    /// `UserDefaults`-backed store; overridable in tests.
    let credentialStore: PasskeyCredentialStore

    // MARK: Initialization

    /// Initializes a `ManagePasskeysProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - credentialStore: Reads, deletes, and clears previously created passkey credentials.
    ///     Defaults to a `UserDefaults`-backed store; overridable in tests.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        credentialStore: PasskeyCredentialStore = DefaultPasskeyCredentialStore(),
    ) {
        self.coordinator = coordinator
        self.credentialStore = credentialStore
        super.init(state: ManagePasskeysState())
    }

    // MARK: Methods

    override func perform(_ effect: ManagePasskeysEffect) async {
        switch effect {
        case .deleteAll:
            await performDeleteAll()
        case let .deleteCredential(id):
            await performDelete(id: id)
        case .loadCredentials:
            await loadCredentials()
        }
    }

    // MARK: Private

    /// Loads the stored passkey credentials into state, most recently created first.
    ///
    private func loadCredentials() async {
        do {
            state.credentials = try credentialStore.fetchAll().sorted { $0.createdAt > $1.createdAt }
        } catch {
            await coordinator.showErrorAlert(error: error)
        }
    }

    /// Deletes the stored passkey credential with the given identifier and reloads the list.
    ///
    private func performDelete(id: String) async {
        do {
            try credentialStore.delete(id: id)
            await loadCredentials()
        } catch {
            await coordinator.showErrorAlert(error: error)
        }
    }

    /// Deletes all stored passkey credentials and reloads the list.
    ///
    private func performDeleteAll() async {
        do {
            try credentialStore.deleteAll()
            await loadCredentials()
        } catch {
            await coordinator.showErrorAlert(error: error)
        }
    }
}
