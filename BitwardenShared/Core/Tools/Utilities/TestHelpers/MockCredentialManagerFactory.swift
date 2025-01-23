#if SUPPORTS_CXP
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

class MockCredentialImportManager: CredentialImportManager {
    /// The result of calling `importCredentials(token:)`.
    /// A JSON encoded `String` is used as the value instead of the actual object
    /// to avoid crashing on simulators older than iOS 18.2 because of not finding the symbol
    /// thus resulting in bad access error when running the test suite.
    /// Use `JSONEncoder.cxpEncoder.encode` to encode data for this.
    var importCredentialsResult: Result<String, Error> = .failure(BitwardenTestError.example)

    @available(iOS 18.2, *)
    func importCredentials(token: UUID) async throws -> ASExportedCredentialData {
        guard let data = try importCredentialsResult.get().data(using: .utf8) else {
            throw BitwardenError.dataError("importCredentialsResult data not set or not in UTF8")
        }
        return try JSONDecoder.cxpDecoder.decode(
            ASExportedCredentialData.self,
            from: data
        )
    }
}
#endif
