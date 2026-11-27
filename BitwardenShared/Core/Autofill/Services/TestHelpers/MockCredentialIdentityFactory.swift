import AuthenticationServices
import BitwardenSdk
import TestHelpers

@testable import BitwardenShared

class MockCredentialIdentityFactory: CredentialIdentityFactory {
    var createCredentialIdentitiesMocker = InvocationMockerWithThrowingResult<CipherView, [CredentialIdentity]>()
        .throwing(BitwardenTestError.example)
    var createPasswordCredentialIdentitiesResult = [ASPasswordCredentialIdentity]()

    @available(iOS 17.0, *)
    func createCredentialIdentities(
        from cipher: BitwardenSdk.CipherView,
        accountHasPremium: Bool,
    ) async -> [any ASCredentialIdentity] {
        do {
            return try createCredentialIdentitiesMocker.invoke(param: cipher)
                .compactMap(\.asCredentialIdentity)
        } catch {
            return []
        }
    }

    func createPasswordCredentialIdentities(from cipher: BitwardenSdk.CipherView) -> [ASPasswordCredentialIdentity] {
        createPasswordCredentialIdentitiesResult
    }
}
