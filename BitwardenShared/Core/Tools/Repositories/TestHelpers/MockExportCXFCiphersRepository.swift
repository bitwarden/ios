import AuthenticationServices
import BitwardenSdk
import TestHelpers

@testable import BitwardenShared

class MockExportCXFCiphersRepository: ExportCXFCiphersRepository {
    var buildCiphersToExportSummaryResult: [CXFCredentialsResult] = []
    var exportCredentialsData: ImportableAccountProxy?
    var exportCredentialsError: Error?
    var getAllCiphersToExportCXFResult: Result<[Cipher], Error> = .failure(BitwardenTestError.example)
    var getExportVaultDataForCXFResult: Result<ImportableAccountProxy, Error> = .failure(BitwardenTestError.example)

    func buildCiphersToExportSummary(from ciphers: [Cipher]) -> [CXFCredentialsResult] {
        buildCiphersToExportSummaryResult
    }

    @available(iOS 26.0, *)
    func exportCredentials(
        data: ASImportableAccount,
        presentationAnchor: () async -> ASPresentationAnchor,
    ) async throws {
        exportCredentialsData = data
        if let exportCredentialsError {
            throw exportCredentialsError
        }
    }

    func getAllCiphersToExportCXF() async throws -> [Cipher] {
        try getAllCiphersToExportCXFResult.get()
    }

    @available(iOS 26.0, *)
    func getExportVaultDataForCXF() async throws -> ASImportableAccount {
        guard let result = try getExportVaultDataForCXFResult.get() as? ASImportableAccount else {
            throw MockExportCXFCiphersRepositoryError.unableToCastToASImportableAccount
        }
        return result
    }
}

protocol ImportableAccountProxy {}

@available(iOS 26.0, *)
extension ASImportableAccount: ImportableAccountProxy {}

enum MockExportCXFCiphersRepositoryError: Error {
    case unableToCastToASImportableAccount
}
