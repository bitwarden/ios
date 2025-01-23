import AuthenticationServices
import Foundation
import XCTest

@testable import BitwardenShared

class MockExportVaultService: ExportVaultService {
    var didClearFiles = false

    var exportVaultForCXPResult: Result<ImportableAccountProxy, Error> = .failure(BitwardenTestError.example)
    var exportVaultContentsFormat: ExportFileType?
    var exportVaultContentResult: Result<String, Error> = .failure(BitwardenTestError.example)

    var mockFileName: String = "mockExport.json"

    var writeToFileResult: Result<URL, Error> = .failure(BitwardenTestError.example)

    func clearTemporaryFiles() {
        didClearFiles = true
    }

    #if SUPPORTS_CXP
    @available(iOS 18.2, *)
    func exportVaultForCXP() async throws -> ASImportableAccount {
        guard let result = try exportVaultForCXPResult.get() as? ASImportableAccount else {
            throw MockExportVaultServiceError.unableToCastToASImportableAccount
        }
        return result
    }
    #endif

    func exportVaultFileContents(format: BitwardenShared.ExportFileType) async throws -> String {
        exportVaultContentsFormat = format
        return try exportVaultContentResult.get()
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

protocol ImportableAccountProxy {}

#if SUPPORTS_CXP
@available(iOS 18.2, *)
extension ASImportableAccount: ImportableAccountProxy {}
#endif

enum MockExportVaultServiceError: Error {
    case unableToCastToASImportableAccount
}
