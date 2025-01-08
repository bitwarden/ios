#if compiler(>=6.0.3)
import AuthenticationServices
import BitwardenSdk

@testable import BitwardenShared

class MockCredentialManagerFactory: CredentialManagerFactory {
    var exportManager: CredentialExportManager?
    var importManager: CredentialImportManager?

    @available(iOS 18.2, *)
    func createExportManager(presentationAnchor: ASPresentationAnchor) -> any CredentialExportManager {
        exportManager ?? MockCredentialExportManager()
    }

    @available(iOS 18.2, *)
    func createImportManager() -> CredentialImportManager {
        importManager ?? MockCredentialImportManager()
    }
}

@available(iOS 18.2, *)
class MockCredentialExportManager: CredentialExportManager {
    var exportCredentialsCalled = false
    var exportCredentialsData: ASExportedCredentialData?
    var exportCredentialsError: Error?

    func exportCredentials(_ credentialData: ASExportedCredentialData) async throws {
        exportCredentialsCalled = true
        exportCredentialsData = credentialData
        if let exportCredentialsError {
            throw exportCredentialsError
        }
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
