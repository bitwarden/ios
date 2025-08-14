import AuthenticationServices
import BitwardenSdk
import TestHelpers

@testable import BitwardenShared

class MockExportCXFCiphersRepository: ExportCXFCiphersRepository {
    var buildCiphersToExportSummaryResult: [CXFCredentialsResult] = []
    #if SUPPORTS_CXP
    var exportCredentialsData: ImportableAccountProxy?
    var exportCredentialsError: Error?
    #endif
    var getAllCiphersToExportCXFResult: Result<[Cipher], Error> = .failure(BitwardenTestError.example)
    #if SUPPORTS_CXP
    var getExportVaultDataForCXFResult: Result<ImportableAccountProxy, Error> = .failure(BitwardenTestError.example)
    #endif

    func buildCiphersToExportSummary(from ciphers: [Cipher]) -> [CXFCredentialsResult] {
        buildCiphersToExportSummaryResult
    }

    #if SUPPORTS_CXP

    @available(iOS 26.0, *)
    func exportCredentials(
        data: ASImportableAccount,
        presentationAnchor: () async -> ASPresentationAnchor
    ) async throws {
        exportCredentialsData = data
        if let exportCredentialsError {
            throw exportCredentialsError
        }
    }

    #endif

    func getAllCiphersToExportCXF() async throws -> [Cipher] {
        try getAllCiphersToExportCXFResult.get()
    }

    #if SUPPORTS_CXP

    @available(iOS 26.0, *)
    func getExportVaultDataForCXF() async throws -> ASImportableAccount {
        guard let result = try getExportVaultDataForCXFResult.get() as? ASImportableAccount else {
            throw MockExportCXFCiphersRepositoryError.unableToCastToASImportableAccount
        }
        return result
    }

    #endif
}

protocol ImportableAccountProxy {}

#if SUPPORTS_CXP
@available(iOS 26.0, *)
extension ASImportableAccount: ImportableAccountProxy {}
#endif

enum MockExportCXFCiphersRepositoryError: Error {
    case unableToCastToASImportableAccount
}
