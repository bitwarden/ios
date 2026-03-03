import AuthenticationServices
import BitwardenSdk
import Foundation
import TestHelpers
import XCTest

@testable import BitwardenShared

class MockExportVaultService: ExportVaultService {
    var didClearFiles = false
    var exportVaultContentsFormat: ExportFileType?
    var exportVaultContentsIncludeArchived: Bool?
    var exportVaultContentResult: Result<String, Error> = .failure(BitwardenTestError.example)
    var fetchAllCiphersToExportIncludeArchived: Bool?
    var fetchAllCiphersToExportResult: Result<[BitwardenSdk.Cipher], Error> = .success([])
    var mockFileName: String = "mockExport.json"
    var writeToFileResult: Result<URL, Error> = .failure(BitwardenTestError.example)

    func clearTemporaryFiles() {
        didClearFiles = true
    }

    func exportVaultFileContents(
        format: BitwardenShared.ExportFileType,
        includeArchivedItems: Bool,
    ) async throws -> String {
        exportVaultContentsFormat = format
        exportVaultContentsIncludeArchived = includeArchivedItems
        return try exportVaultContentResult.get()
    }

    func fetchAllCiphersToExport(includeArchivedItems: Bool) async throws -> [BitwardenSdk.Cipher] {
        fetchAllCiphersToExportIncludeArchived = includeArchivedItems
        return try fetchAllCiphersToExportResult.get()
    }

    func generateExportFileName(
        prefix: String?,
        extension fileExtension: String,
    ) -> String {
        mockFileName
    }

    func writeToFile(name fileName: String, content fileContent: String) throws -> URL {
        try writeToFileResult.get()
    }
}
