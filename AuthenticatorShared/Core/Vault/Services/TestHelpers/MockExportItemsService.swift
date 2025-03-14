import Foundation
import TestHelpers

@testable import AuthenticatorShared

class MockExportItemsService: ExportItemsService {
    var didClearFiles = false

    var exportFileContentsFormat: ExportFileType?
    var exportFileContentResult: Result<String, Error> = .failure(BitwardenTestError.example)

    var mockFileName: String = "mockExport.json"

    var writeToFileResult: Result<URL, Error> = .failure(BitwardenTestError.example)

    func clearTemporaryFiles() {
        didClearFiles = true
    }

    func exportFileContents(format: ExportFileType) async throws -> String {
        exportFileContentsFormat = format
        return try exportFileContentResult.get()
    }

    func generateExportFileName(format: ExportFileType) -> String {
        mockFileName
    }

    func writeToFile(name fileName: String, content fileContent: String) throws -> URL {
        try writeToFileResult.get()
    }
}
