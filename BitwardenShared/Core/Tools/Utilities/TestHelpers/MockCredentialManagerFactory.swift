#if compiler(>=6.0.3)
import AuthenticationServices
import BitwardenSdk

@testable import BitwardenShared

class MockCredentialManagerFactory: CredentialManagerFactory {
    var importManager: CredentialImportManager?

    @available(iOS 18.2, *)
    func createImportManager() -> CredentialImportManager {
        importManager ?? MockCredentialImportManager()
    }
}

@available(iOS 18.2, *)
class MockCredentialImportManager: CredentialImportManager {
    var importCredentialsResult: Result<ASExportedCredentialData, Error> = .failure(BitwardenTestError.example)

    @available(iOS 18.2, *)
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData {
        try importCredentialsResult.get()
    }
}
#endif
