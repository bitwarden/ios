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
    func exportCredentials(importableAccount: ASImportableAccount) async throws

    @available(iOS 26.0, *)
    func requestExport(forExtensionBundleIdentifier: String?) async throws -> CredentialExportManagerExportOptions
}

// MARK: - CredentialImportManager

protocol CredentialImportManager: AnyObject {
    @available(iOS 26.0, *)
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData
}

// MARK: - Helpers

@available(iOS 26.0, *)
extension ASCredentialExportManager: CredentialExportManager {
    func exportCredentials(importableAccount: ASImportableAccount) async throws {
        // there are no unit tests for this function as requestExport is hard to mock given that
        // ASCredentialExportManager.ExportOptions doesn't have a handy initializer.
        let options = try await requestExport(forExtensionBundleIdentifier: nil)
        guard let exportOptions = options as? ASCredentialExportManager.ExportOptions else {
            throw BitwardenError.generalError(
                type: "Wrong export options",
                message: "The credential manager returned wrong export options type.",
            )
        }

        try await exportCredentials(
            ASExportedCredentialData(
                accounts: [importableAccount],
                formatVersion: exportOptions.formatVersion,
                exporterRelyingPartyIdentifier: Bundle.main.appIdentifier,
                exporterDisplayName: "Bitwarden",
                timestamp: Date.now,
            ),
        )
    }

    func requestExport(forExtensionBundleIdentifier: String?) async throws -> any CredentialExportManagerExportOptions {
        try await requestExport(for: forExtensionBundleIdentifier)
    }
}

@available(iOS 26.0, *)
extension ASCredentialImportManager: CredentialImportManager {}
