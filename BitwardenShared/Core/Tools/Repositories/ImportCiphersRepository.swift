import AuthenticationServices
import BitwardenSdk
import Foundation

/// A protocol for a `ImportCiphersRepository` which manages importing credentials needed by the UI layer.
///
protocol ImportCiphersRepository: AnyObject {
    /// Performs an API request to import ciphers in the vault.
    /// - Parameters:
    ///   - credentialImportToken: The token used in `ASCredentialImportManager` to get the credentials to import.
    ///   - onProgress: Closure to update progress.
    /// - Returns: A dictionary containing the localized cipher type (key) and count (value) of that type
    /// that was imported, e.g. ["Passwords": 3, "Cards": 2].
    @available(iOS 18.2, *)
    func importCiphers(
        credentialImportToken: UUID,
        onProgress: @MainActor (Double) -> Void
    ) async throws -> [ImportedCredentialsResult]
}

// MARK: - DefaultImportCiphersRepository

/// A default implementation of a `ImportCiphersRepository`.
///
class DefaultImportCiphersRepository {
    // MARK: Properties

    /// The service that handles common client functionality such as encryption and decryption.
    let clientService: ClientService

    /// The factory to create credential managers.
    let credentialManagerFactory: CredentialManagerFactory

    /// The service that manages importing credentials.
    let importCiphersService: ImportCiphersService

    /// The service used to handle syncing vault data with the API.
    let syncService: SyncService

    // MARK: Initialization

    /// Initialize a `DefaultImportCiphersRepository`
    ///
    /// - Parameters:
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - credentialManagerFactory: A factory to create credential managers.
    ///   - importCiphersService: A service that manages importing credentials.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///
    init(
        clientService: ClientService,
        credentialManagerFactory: CredentialManagerFactory,
        importCiphersService: ImportCiphersService,
        syncService: SyncService
    ) {
        self.clientService = clientService
        self.credentialManagerFactory = credentialManagerFactory
        self.importCiphersService = importCiphersService
        self.syncService = syncService
    }
}

// MARK: ImportCiphersRepository

extension DefaultImportCiphersRepository: ImportCiphersRepository {
    @available(iOS 18.2, *)
    func importCiphers( // swiftlint:disable:this function_body_length
        credentialImportToken: UUID,
        onProgress: @MainActor (Double) -> Void
    ) async throws -> [ImportedCredentialsResult] {
        #if SUPPORTS_CXP

        let credentialData = try await credentialManagerFactory.createImportManager().importCredentials(
            token: credentialImportToken
        )
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

        await onProgress(0.3)

        _ = try await importCiphersService
            .importCiphers(
                ciphers: ciphers,
                folders: [],
                folderRelationships: []
            )

        await onProgress(0.8)

        try await syncService.fetchSync(forceSync: true)

        let importedCredentialsCount: [ImportedCredentialsResult] = [
            ImportedCredentialsResult(
                count: ciphers.count { $0.type == .login && $0.login?.fido2Credentials?.isEmpty != false },
                type: .password
            ),
            ImportedCredentialsResult(
                count: ciphers.count { $0.type == .login && $0.login?.fido2Credentials?.isEmpty == false },
                type: .passkey
            ),
            ImportedCredentialsResult(
                count: ciphers.count { $0.type == .card },
                type: .card
            ),
            ImportedCredentialsResult(
                count: ciphers.count { $0.type == .identity },
                type: .identity
            ),
            ImportedCredentialsResult(
                count: ciphers.count { $0.type == .secureNote },
                type: .secureNote
            ),
            ImportedCredentialsResult(
                count: ciphers.count { $0.type == .sshKey },
                type: .sshKey
            ),
        ]

        await onProgress(1.0)

        return importedCredentialsCount.filter { !$0.isEmpty }
        #else
        return []
        #endif
    }
}

// MARK: - ImportCiphersRepositoryError

enum ImportCiphersRepositoryError: Error {
    case noDataFound
    case dataEncodingFailed
}
