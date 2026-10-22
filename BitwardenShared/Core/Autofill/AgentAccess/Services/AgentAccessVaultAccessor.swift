import BitwardenSdk
import Foundation

// MARK: - AgentAccessVaultAccessor

/// A protocol for an object that reads the vault items Agent Access can share.
///
protocol AgentAccessVaultAccessor: AnyObject { // sourcery: AutoMockable
    /// Returns the logins the user can pick for a query: not deleted, not archived and without
    /// master password reprompt.
    ///
    /// - Parameters:
    ///   - query: What the agent asked for.
    ///   - userId: The ID of the user.
    ///
    func candidates(for query: AgentAccessQuery, userId: String) async throws -> [AgentAccessCandidate]

    /// Returns the credential values of a vault item.
    ///
    /// - Parameters:
    ///   - cipherId: The ID of the vault item.
    ///   - userId: The ID of the user.
    /// - Throws: `AgentAccessError.cipherNotFound` if the item can't be shared.
    ///
    func credential(forCipherId cipherId: String, userId: String) async throws -> AgentAccessSdkCredential

    /// Whether the vault of the user is unlocked.
    func isVaultUnlocked(userId: String) -> Bool
}

// MARK: - DefaultAgentAccessVaultAccessor

/// The default implementation of `AgentAccessVaultAccessor`.
///
final class DefaultAgentAccessVaultAccessor: AgentAccessVaultAccessor {
    // MARK: Properties

    /// The factory used to create helpers that match logins against a URL.
    private let cipherMatchingHelperFactory: CipherMatchingHelperFactory

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service used to manage vault timeout and lock status.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Initialize a `DefaultAgentAccessVaultAccessor`.
    ///
    /// - Parameters:
    ///   - cipherMatchingHelperFactory: The factory used to create helpers that match logins against a URL.
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption
    ///     and decryption.
    ///   - vaultTimeoutService: The service used to manage vault timeout and lock status.
    ///
    init(
        cipherMatchingHelperFactory: CipherMatchingHelperFactory,
        cipherService: CipherService,
        clientService: ClientService,
        vaultTimeoutService: VaultTimeoutService,
    ) {
        self.cipherMatchingHelperFactory = cipherMatchingHelperFactory
        self.cipherService = cipherService
        self.clientService = clientService
        self.vaultTimeoutService = vaultTimeoutService
    }

    // MARK: AgentAccessVaultAccessor

    func candidates(for query: AgentAccessQuery, userId: String) async throws -> [AgentAccessCandidate] {
        let ciphers = try await cipherService.fetchAllCiphers()
        let decrypted = try await clientService.vault(for: userId).ciphers()
            .decryptListWithFailures(ciphers: ciphers)
            .successes
            .filter { $0.type.isLogin && $0.deletedDate == nil && $0.archivedDate == nil && $0.reprompt == .none }

        let matching: [CipherListView]
        switch query {
        case let .domain(value):
            let uri = value.contains("://") ? value : "https://\(value)"
            let helper = await cipherMatchingHelperFactory.make(uri: uri)
            matching = decrypted.filter { helper.doesCipherMatch(cipher: $0) != .none }
        case let .id(value):
            matching = decrypted.filter { $0.id == value }
        case let .search(value):
            let needle = value.lowercased()
            matching = decrypted.filter { cipher in
                let login = cipher.type.loginListView
                return cipher.name.lowercased().contains(needle)
                    || login?.username?.lowercased().contains(needle) == true
                    || login?.uris?.contains { $0.uri?.lowercased().contains(needle) == true } == true
            }
        }

        return matching
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .compactMap { cipher in
                guard let id = cipher.id else { return nil }
                let login = cipher.type.loginListView
                return AgentAccessCandidate(
                    id: id,
                    name: cipher.name,
                    username: login?.username,
                    uri: login?.uris?.first?.uri,
                )
            }
    }

    func credential(forCipherId cipherId: String, userId: String) async throws -> AgentAccessSdkCredential {
        guard let cipher = try await cipherService.fetchCipher(withId: cipherId) else {
            throw AgentAccessError.cipherNotFound
        }
        let view = try await clientService.vault(for: userId).ciphers().decrypt(cipher: cipher)
        guard view.deletedDate == nil, view.archivedDate == nil, view.reprompt == .none, let login = view.login else {
            throw AgentAccessError.cipherNotFound
        }
        let domain = login.uris?.compactMap(\.uri).compactMap { URL(string: $0)?.host }.first
        return AgentAccessSdkCredential(
            username: login.username,
            password: login.password,
            credentialId: cipherId,
            domain: domain,
        )
    }

    func isVaultUnlocked(userId: String) -> Bool {
        !vaultTimeoutService.isLocked(userId: userId)
    }
}
