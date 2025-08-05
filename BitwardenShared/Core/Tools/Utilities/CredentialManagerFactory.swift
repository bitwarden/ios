import AuthenticationServices
import Foundation

// MARK: - CredentialManagerFactory

protocol CredentialManagerFactory {
    @available(iOS 26.0, *)
    func createExportManager(presentationAnchor: ASPresentationAnchor) -> CredentialExportManager

    @available(iOS 26.0, *)
    func createImportManager() -> CredentialImportManager
}

// MARK: - DefaultCredentialManagerFactory

struct DefaultCredentialManagerFactory: CredentialManagerFactory {
    @available(iOS 26.0, *)
    func createExportManager(presentationAnchor: ASPresentationAnchor) -> any CredentialExportManager {
        ASCredentialExportManager(presentationAnchor: presentationAnchor)
    }

    @available(iOS 26.0, *)
    func createImportManager() -> any CredentialImportManager {
        ASCredentialImportManager()
    }
}

// MARK: - CredentialExportManagerExportOptions

protocol CredentialExportManagerExportOptions {}

// MARK: - ASCredentialExportManager.ExportOptions

@available(iOS 26.0, *)
extension ASCredentialExportManager.ExportOptions: CredentialExportManagerExportOptions {}

// MARK: - CredentialExportManager

protocol CredentialExportManager: AnyObject {
    @available(iOS 26.0, *)
    func exportCredentials(_ credentialData: ASExportedCredentialData) async throws

    @available(iOS 26.0, *)
    func requestExport(forExtensionBundleIdentifier: String?) async throws -> CredentialExportManagerExportOptions
}

// MARK: - CredentialImportManager

protocol CredentialImportManager: AnyObject {
    @available(iOS 26.0, *)
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData
}

// MARK: - Helpers

// This section is needed for compiling the project on Xcode version < 16.2
// and to ease unit testing.

#if SUPPORTS_CXP

@available(iOS 26.0, *)
extension ASCredentialExportManager: CredentialExportManager {
    func requestExport(forExtensionBundleIdentifier: String?) async throws -> any CredentialExportManagerExportOptions {
        try await requestExport(for: forExtensionBundleIdentifier)
    }
}

@available(iOS 26.0, *)
extension ASCredentialImportManager: CredentialImportManager {}

#else

class ASCredentialImportManager: CredentialImportManager {
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData {
        ASExportedCredentialData()
    }
}

class ASCredentialExportManager: CredentialExportManager {
    struct ExportOptions: CredentialExportManagerExportOptions {}

    init(presentationAnchor: ASPresentationAnchor) {}

    func exportCredentials(_ credentialData: ASExportedCredentialData) async throws {}

    @available(iOS 26.0, *)
    func requestExport(forExtensionBundleIdentifier: String?) async throws -> CredentialExportManagerExportOptions {
        ASCredentialExportManager.ExportOptions()
    }
}

struct ASExportedCredentialData {}

#endif
