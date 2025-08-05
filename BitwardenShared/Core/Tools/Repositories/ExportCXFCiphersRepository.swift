import AuthenticationServices
import BitwardenKit
import BitwardenSdk

/// Protocol for a repository to handle exporting ciphers in Credential Exchange Format.
///
protocol ExportCXFCiphersRepository {
    /// Builds the summary of the ciphers to export using `CXFCredentialsResult`.
    ///
    /// - Parameter ciphers: Ciphers to build the summary from.
    /// - Returns: An array of `CXFCredentialsResult` that has the summary of the ciphers to export by type.
    func buildCiphersToExportSummary(from ciphers: [Cipher]) -> [CXFCredentialsResult]

    #if SUPPORTS_CXP
    /// Export the credentials using the Credential Exchange flow.
    ///
    /// - Parameter data: Data to export.
    @available(iOS 26.0, *)
    func exportCredentials(data: ASImportableAccount, presentationAnchor: () async -> ASPresentationAnchor) async throws
    #endif

    /// Gets all ciphers to export in Credential Exchange flow.
    ///
    /// - Returns: Ciphers to export.
    func getAllCiphersToExportCXF() async throws -> [Cipher]

    #if SUPPORTS_CXP
    /// Exports the vault creating the `ASImportableAccount` to be used in Credential Exchange Protocol.
    ///
    /// - Returns: An `ASImportableAccount`
    @available(iOS 26.0, *)
    func getExportVaultDataForCXF() async throws -> ASImportableAccount
    #endif
}

class DefaultExportCXFCiphersRepository: ExportCXFCiphersRepository {
    // MARK: Properties

    /// The cipher service used by this service.
    private let cipherService: CipherService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The factory to create credential managers.
    private let credentialManagerFactory: CredentialManagerFactory

    /// Builder to be used to create helper objects for the Credential Exchange flow.
    private let cxfCredentialsResultBuilder: CXFCredentialsResultBuilder

    /// The error reporter used by this service.
    private let errorReporter: ErrorReporter

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initializes a new instance of the `DefaultExportCXFCIphersRepository`.
    ///
    /// - Parameters:
    ///   - cipherService: The service for managing ciphers.
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - credentialManagerFactory: A factory to create credential managers.
    ///   - cxfCredentialsResultBuilder: Builder to be used to create helper objects for the Credential Exchange flow.
    ///   - errorReporter: The service for handling errors.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        cipherService: CipherService,
        clientService: ClientService,
        credentialManagerFactory: CredentialManagerFactory,
        cxfCredentialsResultBuilder: CXFCredentialsResultBuilder,
        errorReporter: ErrorReporter,
        stateService: StateService
    ) {
        self.cipherService = cipherService
        self.clientService = clientService
        self.credentialManagerFactory = credentialManagerFactory
        self.cxfCredentialsResultBuilder = cxfCredentialsResultBuilder
        self.errorReporter = errorReporter
        self.stateService = stateService
    }

    // MARK: Methods

    func buildCiphersToExportSummary(from ciphers: [Cipher]) -> [CXFCredentialsResult] {
        guard !ciphers.isEmpty else {
            return []
        }
        return cxfCredentialsResultBuilder.build(from: ciphers).filter { !$0.isEmpty }
    }

    #if SUPPORTS_CXP

    @available(iOS 26.0, *)
    func exportCredentials(
        data: ASImportableAccount,
        presentationAnchor: () async -> ASPresentationAnchor
    ) async throws {
        let manager = await credentialManagerFactory.createExportManager(presentationAnchor: presentationAnchor())

        let options = try await manager.requestExport(forExtensionBundleIdentifier: nil)
        guard let exportOptions = options as? ASCredentialExportManager.ExportOptions else {
            throw BitwardenError.generalError(
                type: "Wrong export options",
                message: "The credential manager returned wrong export options type."
            )
        }

        try await manager.exportCredentials(
            ASExportedCredentialData(
                accounts: [data],
                formatVersion: exportOptions.formatVersion,
                exporterRelyingPartyIdentifier: Bundle.main.appIdentifier,
                exporterDisplayName: "Bitwarden",
                timestamp: Date.now
            )
        )
    }

    #endif

    func getAllCiphersToExportCXF() async throws -> [Cipher] {
        try await cipherService.fetchAllCiphers()
            .filter { $0.deletedDate == nil && $0.organizationId == nil }
    }

    #if SUPPORTS_CXP

    @available(iOS 26.0, *)
    func getExportVaultDataForCXF() async throws -> ASImportableAccount {
        let ciphers = try await getAllCiphersToExportCXF()

        let account = try await stateService.getAccount(userId: nil)
        let sdkAccount = BitwardenSdk.Account(
            id: account.profile.userId,
            email: account.profile.email,
            name: account.profile.name
        )
        let serializedCXF = try await clientService.exporters().exportCxf(account: sdkAccount, ciphers: ciphers)
        return try JSONDecoder.cxfDecoder.decode(ASImportableAccount.self, from: Data(serializedCXF.utf8))
    }

    #endif
}
