import AuthenticationServices
import BitwardenSdk

@testable import BitwardenShared

class MockExportCXFCiphersRepository: ExportCXFCiphersRepository {
    var buildCiphersToExportSummaryResult: [CXFCredentialsResult] = []
    #if compiler(>=6.0.3)
    var exportCredentialsData: ImportableAccountProxy?
    var exportCredentialsError: Error?
    #endif
    var getAllCiphersToExportCXFResult: Result<[Cipher], Error> = .failure(BitwardenTestError.example)
    #if compiler(>=6.0.3)
    var getExportVaultDataForCXFResult: Result<ImportableAccountProxy, Error> = .failure(BitwardenTestError.example)
    #endif

    func buildCiphersToExportSummary(from ciphers: [Cipher]) -> [CXFCredentialsResult] {
        buildCiphersToExportSummaryResult
    }

    #if compiler(>=6.0.3)

    @available(iOS 18.2, *)
    func exportCredentials(data: ASImportableAccount, presentationAnchor: () -> ASPresentationAnchor) async throws {
        exportCredentialsData = data
        if let exportCredentialsError {
            throw exportCredentialsError
        }
    }

    #endif

    func getAllCiphersToExportCXF() async throws -> [Cipher] {
        try getAllCiphersToExportCXFResult.get()
    }

    #if compiler(>=6.0.3)

    @available(iOS 18.2, *)
    func getExportVaultDataForCXF() async throws -> ASImportableAccount {
        guard let result = try getExportVaultDataForCXFResult.get() as? ASImportableAccount else {
            throw MockExportCXFCiphersRepositoryError.unableToCastToASImportableAccount
        }
        return result
    }

    #endif
}

protocol ImportableAccountProxy {}

#if compiler(>=6.0.3)
@available(iOS 18.2, *)
extension ASImportableAccount: ImportableAccountProxy {}
#endif

enum MockExportCXFCiphersRepositoryError: Error {
    case unableToCastToASImportableAccount
}
