import BitwardenKit
import BitwardenSdk
import Foundation

/// The Fido2 credential store implementation that the SDK needs
/// which handles getting/saving credentials for Fido2 flows.
final class Fido2CredentialStoreService: Fido2CredentialStore {
    // MARK: Properties

    /// The service used to manage syncing and updates to the user's ciphers.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to handle syncing vault data with the API
    private let syncService: SyncService

    // MARK: Initialization

    /// Initializes a `Fido2CredentialStoreService`
    /// - Parameters:
    ///   - cipherService: The service used to manage syncing and updates to the user's ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - configService: The service that handles common client functionality such as encryption and decryption.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncService: The service used to handle syncing vault data with the API.
    init(
        cipherService: CipherService,
        clientService: ClientService,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        stateService: StateService,
        syncService: SyncService,
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
        self.configService = configService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.syncService = syncService
    }

    /// Gets all the active login ciphers that have Fido2 credentials.
    /// - Returns: Array of active login ciphers that have Fido2 credentials.
    func allCredentials() async throws -> [BitwardenSdk.CipherListView] {
        let archiveItemsFeatureFlagEnabled: Bool = await configService.getFeatureFlag(.archiveVaultItems)

        return try await clientService.vault().ciphers().decryptList(
            ciphers: cipherService.fetchAllCiphers().filter { cipher in
                cipher.isActiveWithFido2Credentials
                    && (cipher.archivedDate == nil || !archiveItemsFeatureFlagEnabled)
            },
        )
    }

    /// Finds active login ciphers that have Fido2 credentials, match the `ripId` and if `ids` is sent
    /// then filters the one which the Fido2 `credentialId` matches some of the one in `ids`.
    /// - Parameters:
    ///   - ids: An array of possible `credentialId` to filter credentials that matches one of them.
    ///   When `nil` the `credentialId` filter is not applied.
    ///   - ripId: The `ripId` to match the Fido2 credential `rpId`.
    ///   - userHandle: The user handle (user.id) to match the Fido2 credential. When `nil`, the filter is not applied.
    ///   This is used to ensure credentials are only returned for the specific user account.
    /// - Returns: All the ciphers that matches the filter.
    func findCredentials(ids: [Data]?, ripId: String, userHandle: Data?) async throws -> [BitwardenSdk.CipherView] {
        try await findCredentials(ids: ids, ripId: ripId, shouldCheckSync: true, userHandle: userHandle)
    }

    /// Saves a cipher credential that contains a Fido2 credential, either creating it or updating it to server.
    /// - Parameter cred: Cipher/Credential to add/update.
    func saveCredential(cred: BitwardenSdk.EncryptionContext) async throws {
        if cred.cipher.id == nil {
            try await cipherService.addCipherWithServer(cred.cipher, encryptedFor: cred.encryptedFor)
        } else {
            try await cipherService.updateCipherWithServer(cred.cipher, encryptedFor: cred.encryptedFor)
        }
    }

    // MARK: Private methods

    /// Finds active login ciphers that have Fido2 credentials, match the `ripId` and if `ids` is sent
    /// then filters the one which the Fido2 `credentialId` matches some of the one in `ids`.
    /// - Parameters:
    ///   - ids: An array of possible `credentialId` to filter credentials that matches one of them.
    ///   When `nil` the `credentialId` filter is not applied.
    ///   - ripId: The `ripId` to match the Fido2 credential `rpId`.
    ///   - shouldCheckSync: Whether it should check if sync is needed. This is particular useful to avoid
    ///   infinite loops by calling this method recursively.
    ///   - userHandle: The user handle (user.id) to match the Fido2 credential. When `nil`, the filter is not applied.
    ///   This is used to ensure credentials are only returned for the specific user account.
    /// - Returns: All the ciphers that matches the filter.
    private func findCredentials(
        ids: [Data]?,
        ripId: String,
        shouldCheckSync: Bool,
        userHandle: Data?,
    ) async throws -> [BitwardenSdk.CipherView] {
        let activeCiphersWithFido2Credentials = try await cipherService.fetchAllCiphers()
            .filter(\.isActiveWithFido2Credentials)
            .asyncMap { cipher in
                try await self.clientService.vault().ciphers().decrypt(cipher: cipher)
            }

        var needsSync = false
        if shouldCheckSync {
            needsSync = await needsSyncCheckingLocally()
        }

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

            // Filter by userHandle if provided to ensure credential belongs to the specific user
            if let userHandle,
               fido2CredentialAutofillView.userHandle != userHandle {
                continue
            }

            // Only perform sync if it's needed and there are Fido2 credentials with counter.
            if needsSync, fido2CredentialAutofillViews.contains(where: \.hasCounter) {
                do {
                    try await syncService.fetchSync(forceSync: false, isPeriodic: true)

                    // After sync re-call this function to find the up-to-date credentials.
                    return try await findCredentials(
                        ids: ids,
                        ripId: ripId,
                        shouldCheckSync: false,
                        userHandle: userHandle,
                    )
                } catch {
                    errorReporter.log(error: error)
                }
            }

            result.append(cipherView)
        }
        return result
    }

    /// Whether the current user needs to perform a sync. It only performs local verifications.
    /// - Returns: `true` if needed, `false` otherwise.
    private func needsSyncCheckingLocally() async -> Bool {
        do {
            let userId = try await stateService.getActiveAccountId()
            return try await syncService.needsSync(for: userId, onlyCheckLocalData: true)
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }
}

private extension Cipher {
    /// Whether the cipher is active, is a login and has Fido2 credentials.
    var isActiveWithFido2Credentials: Bool {
        // TODO: PM-30129 When FF gets removed, replace `deletedDate == nil` with
        // `isHidden`.
        deletedDate == nil
            && type == .login
            && login?.fido2Credentials?.isEmpty == false
    }
}

#if DEBUG

/// A wrapper of a `Fido2CredentialStore` which adds debugging info for the `Fido2DebuggingReportBuilder`.
final class DebuggingFido2CredentialStoreService: Fido2CredentialStore {
    let fido2CredentialStore: Fido2CredentialStore

    init(fido2CredentialStore: Fido2CredentialStore) {
        self.fido2CredentialStore = fido2CredentialStore
    }

    func findCredentials(ids: [Data]?, ripId: String, userHandle: Data?) async throws -> [BitwardenSdk.CipherView] {
        do {
            let result = try await fido2CredentialStore.findCredentials(ids: ids, ripId: ripId, userHandle: userHandle)
            Fido2DebuggingReportBuilder.builder.withFindCredentialsResult(.success(result))
            return result
        } catch {
            Fido2DebuggingReportBuilder.builder.withFindCredentialsResult(.failure(error))
            throw error
        }
    }

    func allCredentials() async throws -> [BitwardenSdk.CipherListView] {
        do {
            let result = try await fido2CredentialStore.allCredentials()
            Fido2DebuggingReportBuilder.builder.withAllCredentialsResult(.success(result))
            return result
        } catch {
            Fido2DebuggingReportBuilder.builder.withFindCredentialsResult(.failure(error))
            throw error
        }
    }

    func saveCredential(cred: BitwardenSdk.EncryptionContext) async throws {
        do {
            try await fido2CredentialStore.saveCredential(cred: cred)
            Fido2DebuggingReportBuilder.builder.withSaveCredentialCipher(.success(cred.cipher))
        } catch {
            Fido2DebuggingReportBuilder.builder.withFindCredentialsResult(.failure(error))
            throw error
        }
    }
}

#endif
