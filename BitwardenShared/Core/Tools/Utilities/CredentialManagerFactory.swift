import AuthenticationServices
import Foundation

protocol CredentialManagerFactory {
    @available(iOS 18.2, *)
    func createImportManager() -> CredentialImportManager
}

struct DefaultCredentialManagerFactory: CredentialManagerFactory {
    @available(iOS 18.2, *)
    func createImportManager() -> any CredentialImportManager {
        ASCredentialImportManager()
    }
}

protocol CredentialImportManager: AnyObject {
    @available(iOS 18.2, *)
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData
}

#if compiler(>=6.0.3)

@available(iOS 18.2, *)
extension ASCredentialImportManager: CredentialImportManager {}

#else

class ASCredentialImportManager: CredentialImportManager {
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData {
        ASExportedCredentialData()
    }
}

struct ASExportedCredentialData {}

#endif
