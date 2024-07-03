import AuthenticationServices
import Foundation

@testable import BitwardenShared

@available(iOS 17.0, *)
class MockFido2AppExtensionDelegate: MockAppExtensionDelegate, Fido2AppExtensionDelegate {
    var completeRegistrationRequestMocker = InvocationMocker<ASPasskeyRegistrationCredential>()
    var getRequestForFido2CreationResult: ASPasskeyCredentialRequest?

    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential) {
        completeRegistrationRequestMocker.invoke(param: asPasskeyRegistrationCredential)
    }

    func getRequestForFido2Creation() -> ASPasskeyCredentialRequest? {
        getRequestForFido2CreationResult
    }
}
