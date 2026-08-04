import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - SDKFido2CredentialStore

/// An in-memory `Fido2CredentialStore` for the SDK-backed passkey scenarios. Credentials exist
/// only for the lifetime of the app process — there's no real vault to persist them in, and the
/// SDK-encrypted `Cipher`s this stores can't be decrypted again once the ephemeral session's
/// crypto keys are gone anyway, so persisting them across launches wouldn't help.
///
actor SDKFido2CredentialStore: Fido2CredentialStore {
    // MARK: Private Properties

    /// The SDK-encrypted ciphers created for this session, in the order they were saved.
    private var ciphers: [Cipher] = []

    /// Used to decrypt stored ciphers and their Fido2 credentials on read.
    private let vaultClientService: VaultClientService

    // MARK: Initialization

    /// Initializes an `SDKFido2CredentialStore`.
    ///
    /// - Parameter vaultClientService: Used to decrypt stored ciphers and their Fido2
    ///   credentials on read.
    ///
    init(vaultClientService: VaultClientService) {
        self.vaultClientService = vaultClientService
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
            guard fido2Credentials.contains(where: { $0.rpId == ripId }) else { continue }
            matches.append(cipherView)
        }
        return matches
    }

    func saveCredential(cred: EncryptionContext) async throws {
        ciphers.append(cred.cipher)
    }
}
