import BitwardenSdk
import Foundation

class Fido2CredentialStoreService: Fido2CredentialStore {
    // MARK: Properties

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to handle syncing vault data with the API
    private let syncService: SyncService

    // MARK: Initialization

    /// Initializes a `Fido2CredentialStoreService`
    /// - Parameters:
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - syncService: The service used to handle syncing vault data with the API.
    init(
        cipherService: CipherService,
        clientService: ClientService,
        errorReporter: ErrorReporter,
        syncService: SyncService
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.syncService = syncService
    }

    func allCredentials() async throws -> [BitwardenSdk.CipherView] {
        do {
            try await syncService.fetchSync(forceSync: false)
        } catch {
            errorReporter.log(error: error)
        }

        return try await cipherService.fetchAllCiphers()
            .filter(\.isAciveWithFido2Credentials)
            .asyncMap { cipher in
                try await self.clientService.vault().ciphers().decrypt(cipher: cipher)
            }
    }

    func findCredentials(ids: [Data]?, ripId: String) async throws -> [BitwardenSdk.CipherView] {
        do {
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
        } catch {
            let err = error
            return []
        }
    }

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
    var isAciveWithFido2Credentials: Bool {
        deletedDate == nil
            && type == .login
            && login?.fido2Credentials?.isEmpty == false
    }
}
