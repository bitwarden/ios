import AuthenticationServices
import BitwardenSdk
import Foundation

/// A protocol for a `ImportCiphersRepository` which manages importing credentials needed by the UI layer.
///
protocol ImportCiphersRepository: AnyObject {
    /// Performs an API request to import ciphers in the vault.
    /// - Parameters:
    ///   - credentialImportToken: The token used in `ASCredentialImportManager` to get the credentials to import.
    /// - Returns: A dictionary containing the localized cipher type (key) and count (value) of that type
    /// that was imported, e.g. ["Passwords": 3, "Cards": 2].
    @available(iOS 18.2, *)
    func importCiphers(credentialImportToken: UUID) async throws -> [ImportedCredentialsResult]
}

// MARK: - DefaultImportCiphersRepository

/// A default implementation of a `ImportCiphersRepository`.
///
class DefaultImportCiphersRepository {
    // MARK: Properties

    /// The service that handles common client functionality such as encryption and decryption.
    let clientService: ClientService

    /// The service that manages importing credentials.
    let importCiphersService: ImportCiphersService

    /// The service used to handle syncing vault data with the API.
    let syncService: SyncService

    // MARK: Initialization

    /// Initialize a `DefaultImportCiphersRepository`
    ///
    /// - Parameters:
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - importCiphersService: A service that manages importing credentials.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///
    init(
        clientService: ClientService,
        importCiphersService: ImportCiphersService,
        syncService: SyncService
    ) {
        self.clientService = clientService
        self.importCiphersService = importCiphersService
        self.syncService = syncService
    }
}

// MARK: ImportCiphersRepository

extension DefaultImportCiphersRepository: ImportCiphersRepository {
    @available(iOS 18.2, *)
    func importCiphers( // swiftlint:disable:this function_body_length
        credentialImportToken: UUID
    ) async throws -> [ImportedCredentialsResult] {
        #if compiler(>=6.0.3)

        let credentialData = try await ASCredentialImportManager().importCredentials(token: credentialImportToken)
        guard let accountData = credentialData.accounts.first else {
            // this should never happen.
            throw ImportCiphersRepositoryError.noDataFound
        }

        let accountJsonData = try JSONEncoder.cxpEncoder.encode(accountData)
        guard let accountJsonString = String(data: accountJsonData, encoding: .utf8) else {
            // this should never happen.
            throw ImportCiphersRepositoryError.dataEncodingFailed
        }

        let ciphers = try await clientService.exporters().importCxf(payload: accountJsonString)

        _ = try await importCiphersService
            .importCiphers(
                ciphers: ciphers,
                folders: [],
                folderRelationships: []
            )

        try await syncService.fetchSync(forceSync: true)

        var importedCredentialsCount: [ImportedCredentialsResult] = []
        appendImportedCredentialCountIfAny(
            importedCredentialsCount: &importedCredentialsCount,
            ciphers: ciphers,
            localizedType: Localizations.passwords,
            when: { cipher in
                cipher.type == .login && cipher.login?.fido2Credentials?.isEmpty != false
            }
        )
        appendImportedCredentialCountIfAny(
            importedCredentialsCount: &importedCredentialsCount,
            ciphers: ciphers,
            localizedType: Localizations.passkeys,
            when: { cipher in
                cipher.type == .login && cipher.login?.fido2Credentials?.isEmpty == false
            }
        )
        appendImportedCredentialCountIfAny(
            importedCredentialsCount: &importedCredentialsCount,
            ciphers: ciphers,
            localizedType: Localizations.cards,
            when: { $0.type == .card }
        )
        appendImportedCredentialCountIfAny(
            importedCredentialsCount: &importedCredentialsCount,
            ciphers: ciphers,
            localizedType: Localizations.identities,
            when: { $0.type == .identity }
        )
        appendImportedCredentialCountIfAny(
            importedCredentialsCount: &importedCredentialsCount,
            ciphers: ciphers,
            localizedType: Localizations.secureNotes,
            when: { $0.type == .secureNote }
        )
        appendImportedCredentialCountIfAny(
            importedCredentialsCount: &importedCredentialsCount,
            ciphers: ciphers,
            localizedType: Localizations.sshKeys,
            when: { $0.type == .sshKey }
        )
        return importedCredentialsCount
        #else
        return []
        #endif
    }

    // MARK: Private

    /// Appends imported credential count when the condition is true for the count.
    /// - Parameters:
    ///   - importedCredentialsCount: The array to update.
    ///   - ciphers: The ciphers to count.
    ///   - localizedType: The localized type to add if the condition is met.
    ///   - when: The filter to apply to count the ciphers.
    private func appendImportedCredentialCountIfAny(
        importedCredentialsCount: inout [ImportedCredentialsResult],
        ciphers: [Cipher],
        localizedType: String,
        when: (Cipher) -> Bool
    ) {
        let count = ciphers.count { when($0) }
        if count > 0 { // swiftlint:disable:this empty_count
            importedCredentialsCount
                .append(
                    ImportedCredentialsResult(
                        localizedType: localizedType,
                        count: count
                    )
                )
        }
    }
}

// MARK: - ImportCiphersRepositoryError

enum ImportCiphersRepositoryError: Error {
    case noDataFound
    case dataEncodingFailed
}
