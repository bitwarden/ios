import AuthenticationServices
import BitwardenSdk
import TestHelpers

@testable import BitwardenShared

class MockCredentialIdentityFactory: CredentialIdentityFactory {
    var createCredentialIdentitiesMocker = InvocationMockerWithThrowingResult<CipherView, [CredentialIdentity]>()
        .throwing(BitwardenTestError.example)
    // swiftlint:disable:next identifier_name
    var tryCreatePasswordCredentialIdentityResult: ASPasswordCredentialIdentity?

    @available(iOS 17.0, *)
    func createCredentialIdentities(from cipher: BitwardenSdk.CipherView) async -> [any ASCredentialIdentity] {
        do {
            return try createCredentialIdentitiesMocker.invoke(param: cipher)
                .compactMap(\.asCredentialIdentity)
        } catch {
            return []
        }
    }

    func tryCreatePasswordCredentialIdentity(from cipher: BitwardenSdk.CipherView) -> ASPasswordCredentialIdentity? {
        tryCreatePasswordCredentialIdentityResult
    }
}
