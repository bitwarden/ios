#if SUPPORTS_CXP
import AuthenticationServices
import BitwardenSdk
import TestHelpers

@testable import BitwardenShared

class MockCredentialManagerFactory: CredentialManagerFactory {
    var exportManager: CredentialExportManager?
    var importManager: CredentialImportManager?

    @available(iOS 26.0, *)
    func createExportManager(presentationAnchor: ASPresentationAnchor) -> any CredentialExportManager {
        exportManager ?? MockCredentialExportManager()
    }

    @available(iOS 26.0, *)
    func createImportManager() -> CredentialImportManager {
        importManager ?? MockCredentialImportManager()
    }
}

class MockCredentialExportManager: CredentialExportManager {
    var exportCredentialsCalled = false
    /// The data passed as parameter in `exportCredentials(_:)`.
    /// A JSON encoded `String` is used as the value instead of the actual object
    /// to avoid crashing on simulators older than iOS 26.0 because of not finding the symbol
    /// thus resulting in bad access error when running the test suite.
    /// Use `JSONDecoder.cxfDecoder.decode` to decode data for this.
    var exportCredentialsJSONData: String?
    var exportCredentialsError: Error?
    var requestExportResult: Result<CredentialExportManagerExportOptions, Error> = .success(
        MockCredentialExportManagerExportOptions()
    )

    @available(iOS 26.0, *)
    func exportCredentials(_ credentialData: ASExportedCredentialData) async throws {
        exportCredentialsCalled = true

        let data = try JSONEncoder.cxfEncoder.encode(credentialData)
        guard let dataJsonString = String(data: data, encoding: .utf8) else {
            // this should never happen.
            throw BitwardenError.dataError("Failed encoding credential data")
        }
        exportCredentialsJSONData = dataJsonString

        if let exportCredentialsError {
            throw exportCredentialsError
        }
    }

    @available(iOS 26.0, *)
    func requestExport(forExtensionBundleIdentifier: String?) async throws -> CredentialExportManagerExportOptions {
        try requestExportResult.get()
    }
}

class MockCredentialImportManager: CredentialImportManager {
    /// The result of calling `importCredentials(token:)`.
    /// A JSON encoded `String` is used as the value instead of the actual object
    /// to avoid crashing on simulators older than iOS 26.0 because of not finding the symbol
    /// thus resulting in bad access error when running the test suite.
    /// Use `JSONEncoder.cxfEncoder.encode` to encode data for this.
    var importCredentialsResult: Result<String, Error> = .failure(BitwardenTestError.example)

    @available(iOS 26.0, *)
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData {
        guard let data = try importCredentialsResult.get().data(using: .utf8) else {
            throw BitwardenError.dataError("importCredentialsResult data not set or not in UTF8")
        }
        return try JSONDecoder.cxfDecoder.decode(
            ASExportedCredentialData.self,
            from: data
        )
    }
}

struct MockCredentialExportManagerExportOptions: CredentialExportManagerExportOptions {}

#endif
