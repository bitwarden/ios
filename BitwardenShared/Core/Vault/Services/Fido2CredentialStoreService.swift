import BitwardenSdk
import Foundation

/// The Fido2 credential store implementation that the SDK needs
/// which handles getting/saving credentials for Fido2 flows.
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

    /// Gets all the active login ciphers that have Fido2 credentials.
    /// - Returns: Array of active login ciphers that have Fido2 credentials.
    func allCredentials() async throws -> [BitwardenSdk.CipherView] {
        do {
            try await syncService.fetchSync(forceSync: false)
        } catch {
            errorReporter.log(error: error)
        }

        return try await cipherService.fetchAllCiphers()
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

/// A wrapper of a `Fido2CredentialStore` which adds debugging info for the `Fido2DebugginReportBuilder`.
class DebuggingFido2CredentialStoreService: Fido2CredentialStore {
    let fido2CredentialStore: Fido2CredentialStore

    init(fido2CredentialStore: Fido2CredentialStore) {
        self.fido2CredentialStore = fido2CredentialStore
    }

    func findCredentials(ids: [Data]?, ripId: String) async throws -> [BitwardenSdk.CipherView] {
        do {
            let result = try await fido2CredentialStore.findCredentials(ids: ids, ripId: ripId)
            Fido2DebugginReportBuilder.builder.withFindCredentialsResult(.success(result))
            return result
        } catch {
            Fido2DebugginReportBuilder.builder.withFindCredentialsResult(.failure(error))
            throw error
        }
    }

    func allCredentials() async throws -> [BitwardenSdk.CipherView] {
        do {
            let result = try await fido2CredentialStore.allCredentials()
            Fido2DebugginReportBuilder.builder.withAllCredentialsResult(.success(result))
            return result
        } catch {
            Fido2DebugginReportBuilder.builder.withFindCredentialsResult(.failure(error))
            throw error
        }
    }

    func saveCredential(cred: BitwardenSdk.Cipher) async throws {
        do {
            try await fido2CredentialStore.saveCredential(cred: cred)
            Fido2DebugginReportBuilder.builder.withSaveCredentialCipher(.success(cred))
        } catch {
            Fido2DebugginReportBuilder.builder.withFindCredentialsResult(.failure(error))
            throw error
        }
    }
}
