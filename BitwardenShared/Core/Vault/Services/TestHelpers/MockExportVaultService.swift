import AuthenticationServices
import BitwardenSdk
import Foundation
import TestHelpers
import XCTest

@testable import BitwardenShared

class MockExportVaultService: ExportVaultService {
    var didClearFiles = false
    var exportVaultContentsFormat: ExportFileType?
    var exportVaultContentResult: Result<String, Error> = .failure(BitwardenTestError.example)
    var fetchAllCiphersToExportResult: Result<[BitwardenSdk.Cipher], Error> = .success([])
    var mockFileName: String = "mockExport.json"
    var writeToFileResult: Result<URL, Error> = .failure(BitwardenTestError.example)

    func clearTemporaryFiles() {
        didClearFiles = true
    }

    func exportVaultFileContents(format: BitwardenShared.ExportFileType) async throws -> String {
        exportVaultContentsFormat = format
        return try exportVaultContentResult.get()
    }

    func fetchAllCiphersToExport() async throws -> [BitwardenSdk.Cipher] {
        try fetchAllCiphersToExportResult.get()
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
