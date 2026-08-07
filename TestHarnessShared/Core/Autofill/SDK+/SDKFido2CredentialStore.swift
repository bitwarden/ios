import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - SDKFido2CredentialStore

/// A `Fido2CredentialStore` for the SDK-backed passkey scenarios, backed by an injected
/// `SDKCipherStorageService` so credentials survive app relaunches as long as the same synthetic
/// identity — and therefore the same crypto keys — is reconstructed alongside it.
///
actor SDKFido2CredentialStore: Fido2CredentialStore {
    // MARK: Private Properties

    /// Used to persist ciphers across app relaunches.
    private let cipherStorageService: SDKCipherStorageService

    /// The SDK-encrypted ciphers created for this session, in the order they were saved.
    private var ciphers: [Cipher]

    /// When set, `findCredentials` only considers the credential with this ID, ignoring any
    /// others registered for the same relying party. Set via `select(credentialId:)` before an
    /// assertion that targets a specific credential.
    private var selectedCredentialId: Data?

    /// Used to decrypt stored ciphers and their Fido2 credentials on read.
    private let vaultClientService: VaultClientService

    // MARK: Initialization

    /// Initializes an `SDKFido2CredentialStore`.
    ///
    /// - Parameters:
    ///   - cipherStorageService: Used to persist ciphers across app relaunches.
    ///   - vaultClientService: Used to decrypt stored ciphers and their Fido2 credentials on
    ///     read.
    ///
    init(cipherStorageService: SDKCipherStorageService, vaultClientService: VaultClientService) {
        self.cipherStorageService = cipherStorageService
        self.vaultClientService = vaultClientService
        ciphers = cipherStorageService.loadCiphers()
    }

    // MARK: Methods

    func allCredentials() async throws -> [CipherListView] {
        try await vaultClientService.ciphers().decryptList(ciphers: ciphers)
    }

    func findCredentials(ids: [Data]?, ripId: String, userHandle: Data?) async throws -> [CipherView] {
        var matches: [CipherView] = []
        for cipher in ciphers {
            let cipherView = try await vaultClientService.ciphers().decrypt(cipher: cipher)
            let fido2Credentials = try vaultClientService.ciphers().decryptFido2Credentials(cipherView: cipherView)
            let isMatch = fido2Credentials.contains { credential in
                guard credential.rpId == ripId else { return false }
                guard let selectedCredentialId else { return true }
                let normalizedCredentialId = credential.credentialId
                    .replacingOccurrences(of: "-", with: "")
                    .lowercased()
                let normalizedSelectedId = selectedCredentialId.asHexString()
                return normalizedCredentialId == normalizedSelectedId
            }
            guard isMatch else { continue }
            matches.append(cipherView)
        }
        return matches
    }

    func saveCredential(cred: EncryptionContext) async throws {
        ciphers.append(cred.cipher)
        cipherStorageService.save(ciphers: ciphers)
    }

    /// Restricts subsequent `findCredentials` calls to the credential with this ID, or clears
    /// the restriction when `nil`.
    ///
    /// - Parameter credentialId: The credential ID to restrict to, or `nil` to consider every
    ///   credential registered for the requested relying party.
    ///
    func select(credentialId: Data?) {
        selectedCredentialId = credentialId
    }
}
