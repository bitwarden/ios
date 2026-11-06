import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - DefaultFido2CredentialStore

/// A `Fido2CredentialStore` for the passkey scenarios, backed by an injected
/// `CipherStorageService` so credentials survive app relaunches as long as the same synthetic
/// identity — and therefore the same crypto keys — is reconstructed alongside it.
///
actor DefaultFido2CredentialStore: Fido2CredentialStore {
    // MARK: Private Properties

    /// Used to persist ciphers across app relaunches.
    private let cipherStorageService: CipherStorageService

    /// The SDK-encrypted ciphers created for this session, in the order they were saved.
    private var ciphers: [Cipher]

    /// Used to decrypt stored ciphers' Fido2 credentials on read.
    private let platformClientService: PlatformClientService

    /// Used to decrypt stored ciphers on read.
    private let vaultClientService: VaultClientService

    // MARK: Initialization

    /// Initializes an `DefaultFido2CredentialStore`.
    ///
    /// - Parameters:
    ///   - cipherStorageService: Used to persist ciphers across app relaunches.
    ///   - platformClientService: Used to decrypt stored ciphers' Fido2 credentials on read.
    ///   - vaultClientService: Used to decrypt stored ciphers on read.
    ///
    init(
        cipherStorageService: CipherStorageService,
        platformClientService: PlatformClientService,
        vaultClientService: VaultClientService,
    ) {
        self.cipherStorageService = cipherStorageService
        self.platformClientService = platformClientService
        self.vaultClientService = vaultClientService
        ciphers = cipherStorageService.loadCiphers()
    }

    // MARK: Methods

    func allCredentials() async throws -> [CipherListView] {
        try await vaultClientService.ciphers().decryptList(ciphers: ciphers)
    }

    /// Deletes the credential backed by the cipher with the given ID, if one exists, and persists
    /// the updated list via the injected `CipherStorageService`.
    ///
    /// - Parameter cipherId: The ID of the cipher to delete.
    ///
    func deleteCredential(cipherId: String) {
        ciphers.removeAll { $0.id == cipherId }
        cipherStorageService.save(ciphers: ciphers)
    }

    func findCredentials(ids: [Data]?, ripId: String, userHandle: Data?) async throws -> [CipherView] {
        var matches: [CipherView] = []
        for cipher in ciphers {
            let cipherView = try await vaultClientService.ciphers().decrypt(cipher: cipher)
            let autofillCredentials = try platformClientService.fido2()
                .decryptFido2AutofillCredentials(cipherView: cipherView)
            let isMatch = autofillCredentials.contains { credential in
                guard credential.rpId == ripId else { return false }
                if let ids, !ids.contains(credential.credentialId) { return false }
                if let userHandle, credential.userHandle != userHandle { return false }
                return true
            }
            guard isMatch else { continue }
            matches.append(cipherView)
        }
        return matches
    }

    func saveCredential(cred: EncryptionContext) async throws {
        if let id = cred.cipher.id, let index = ciphers.firstIndex(where: { $0.id == id }) {
            ciphers[index] = cred.cipher
        } else {
            ciphers.append(cred.cipher)
        }
        cipherStorageService.save(ciphers: ciphers)
    }
}
