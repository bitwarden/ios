import BitwardenSdk

// MARK: - MockClientExporters

/// A mocked `ClientExportersProtocol`.
///
class MockClientExporters {
    // MARK: Properties

    /// The ciphers exported in a call to `exportVault(_:)` or `exportOrganizationVault(_:)`.
    var ciphers = [BitwardenSdk.Cipher]()

    /// The collections exported in a call to `exportOrganizationVault(_:)`.
    var collections = [BitwardenSdk.Collection]()

    /// The result of a call to `exportOrganizationVault(_:)`
    var exportOrganizationVaultResult: Result<String, Error> = .failure(AuthenticatorTestError.example)

    /// The result of a call to `exportVault(_:)`
    var exportVaultResult: Result<String, Error> = .failure(AuthenticatorTestError.example)

    /// The folders exported in a call to `exportVault(_:)`.
    var folders = [BitwardenSdk.Folder]()

    /// The format of the export in a call to `exportVault(_:)` or `exportOrganizationVault(_:)`.
    var format: BitwardenSdk.ExportFormat?
}

// MARK: - ClientExportersProtocol

extension MockClientExporters: ClientExportersProtocol {
    func exportOrganizationVault(
        collections: [BitwardenSdk.Collection],
        ciphers: [BitwardenSdk.Cipher],
        format: BitwardenSdk.ExportFormat
    ) async throws -> String {
        self.collections = collections
        self.ciphers = ciphers
        self.format = format
        return try exportOrganizationVaultResult.get()
    }

    func exportVault(
        folders: [BitwardenSdk.Folder],
        ciphers: [BitwardenSdk.Cipher],
        format: BitwardenSdk.ExportFormat
    ) async throws -> String {
        self.folders = folders
        self.ciphers = ciphers
        self.format = format
        return try exportVaultResult.get()
    }
}
