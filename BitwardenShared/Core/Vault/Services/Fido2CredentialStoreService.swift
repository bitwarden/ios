import BitwardenSdk
import Foundation

class Fido2CredentialStoreService: Fido2CredentialStore {
    // MARK: Properties

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    // MARK: Initialization

    /// Initializes a `Fido2CredentialStoreService`
    /// - Parameters:
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    init(cipherService: CipherService, clientService: ClientService) {
        self.cipherService = cipherService
        self.clientService = clientService
    }

    /// Gets all the active login ciphers that have Fido2 credentials.
    /// - Returns: Array of active login ciphers that have Fido2 credentials.
    func allCredentials() async throws -> [BitwardenSdk.CipherView] {
        try await cipherService.fetchAllCiphers()
            .filter(\.isActiveWithFido2Credentials)
            .asyncMap { cipher in
                try await self.clientService.vault().ciphers().decrypt(cipher: cipher)
            }
    }

    /// Finds active login ciphers that have Fido2 credentials, match the `ripId` and if `ids` is sent
    /// then filters the one which the Fido2 `credentialId` matches some of the one in `ids`.
    /// - Parameters:
    ///   - ids: An array of possible `credentialId` to filter credentials that matches one of them.
    ///   When `nil` the `credentialId` filter is not applied.
    ///   - ripId: The `ripId` to match the Fido2 credential `rpId`.
    /// - Returns: All the ciphers that matches the filter.
    func findCredentials(ids: [Data]?, ripId: String) async throws -> [BitwardenSdk.CipherView] {
        let activeCiphersWithFido2Credentials = try await allCredentials()

        var result = [BitwardenSdk.CipherView]()
        for cipherView in activeCiphersWithFido2Credentials {
            let fido2CredentialAutofillViews = try await clientService.platform()
                .fido2()
                .decryptFido2AutofillCredentials(cipherView: cipherView)

            guard let fido2CredentialAutofillView = fido2CredentialAutofillViews[safeIndex: 0],
                  ripId == fido2CredentialAutofillView.rpId else {
                continue
            }

            if let ids,
               !ids.contains(fido2CredentialAutofillView.credentialId) {
                continue
            }

            result.append(cipherView)
        }
        return result
    }

    /// Saves a cipher credential that contains a Fido2 credential, either creating it or updating it to server.
    /// - Parameter cred: Cipher/Credential to add/update.
    func saveCredential(cred: BitwardenSdk.Cipher) async throws {
        if cred.id == nil {
            try await cipherService.addCipherWithServer(cred)
        } else {
            try await cipherService.updateCipherWithServer(cred)
        }
    }
}

private extension Cipher {
    /// Whether the cipher is active, is a login and has Fido2 credentials.
    var isActiveWithFido2Credentials: Bool {
        deletedDate == nil
            && type == .login
            && login?.fido2Credentials?.isEmpty == false
    }
}
