import AuthenticationServices
import BitwardenSdk

@testable import BitwardenShared

class MockCredentialIdentityFactory: CredentialIdentityFactory {
    var createCredentialIdentitiesMocker = InvocationMockerWithThrowingResult<CipherView, [CredentialIdentity]>()
        .throwing(BitwardenTestError.example)
    // swiftlint:disable:next identifier_name
    var tryCreatePasswordCredentialIdentityResult: ASPasswordCredentialIdentity?

    @available(iOS 17.0, *)
    func createCredentialIdentities(from cipher: BitwardenSdk.CipherView) async throws -> [any ASCredentialIdentity] {
        try createCredentialIdentitiesMocker.invoke(param: cipher)
            .compactMap(\.asCredentialIdentity)
    }

    func tryCreatePasswordCredentialIdentity(from cipher: BitwardenSdk.CipherView) -> ASPasswordCredentialIdentity? {
        tryCreatePasswordCredentialIdentityResult
    }
}
