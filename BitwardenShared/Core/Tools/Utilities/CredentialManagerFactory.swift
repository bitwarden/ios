import AuthenticationServices
import Foundation

// MARK: - CredentialManagerFactory

protocol CredentialManagerFactory {
    @available(iOS 18.2, *)
    func createExportManager(presentationAnchor: ASPresentationAnchor) -> CredentialExportManager

    @available(iOS 18.2, *)
    func createImportManager() -> CredentialImportManager
}

// MARK: - DefaultCredentialManagerFactory

struct DefaultCredentialManagerFactory: CredentialManagerFactory {
    @available(iOS 18.2, *)
    func createExportManager(presentationAnchor: ASPresentationAnchor) -> any CredentialExportManager {
        ASCredentialExportManager(presentationAnchor: presentationAnchor)
    }

    @available(iOS 18.2, *)
    func createImportManager() -> any CredentialImportManager {
        ASCredentialImportManager()
    }
}

// MARK: - CredentialExportManager

protocol CredentialExportManager: AnyObject {
    @available(iOS 18.2, *)
    func exportCredentials(_ credentialData: ASExportedCredentialData) async throws
}

// MARK: - CredentialImportManager

protocol CredentialImportManager: AnyObject {
    @available(iOS 18.2, *)
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData
}

// MARK: - Helpers

// This section is needed for compiling the project on Xcode version < 16.2
// and to ease unit testing.

#if compiler(>=6.0.3)

@available(iOS 18.2, *)
extension ASCredentialExportManager: CredentialExportManager {}

@available(iOS 18.2, *)
extension ASCredentialImportManager: CredentialImportManager {}

#else

class ASCredentialImportManager: CredentialImportManager {
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData {
        ASExportedCredentialData()
    }
}

class ASCredentialExportManager: CredentialExportManager {
    init(presentationAnchor: ASPresentationAnchor) {}

    func exportCredentials(_ credentialData: ASExportedCredentialData) async throws {}
}

struct ASExportedCredentialData {}

#endif
