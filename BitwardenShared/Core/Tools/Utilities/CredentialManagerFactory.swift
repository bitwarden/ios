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

// MARK: - Helpers

// This section is needed for compiling the project on Xcode version < 16.2
// and to ease unit testing.

#if SUPPORTS_CXP

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
