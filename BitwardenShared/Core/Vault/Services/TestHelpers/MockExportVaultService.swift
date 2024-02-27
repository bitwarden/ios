import Foundation

@testable import BitwardenShared

class MockExportVaultService: ExportVaultService {
    var didClearFiles = false

    var exportVaultContentResult: Result<String, Error> = .failure(BitwardenTestError.example)

    var mockFileName: String = "mockExport.json"

    var writeToFileResult: Result<URL, Error> = .failure(BitwardenTestError.example)

    func clearTemporaryFiles() {
        didClearFiles = true
    }

    func exportVaultFileContents(format: BitwardenShared.ExportFileType) async throws -> String {
        try exportVaultContentResult.get()
    }

    func generateExportFileName(
        prefix: String?,
        extension fileExtension: String
    ) -> String {
        mockFileName
    }

    func writeToFile(name fileName: String, content fileContent: String) throws -> URL {
        try writeToFileResult.get()
    }
}
