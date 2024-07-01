import AuthenticationServices
import Foundation

@testable import BitwardenShared

@available(iOS 17.0, *)
class MockFido2AppExtensionDelegate: Fido2AppExtensionDelegate {
    var completeRegistrationRequestCalled = false
    var didCancelCalled = false
    var getRequestForFido2CreationResult: ASPasskeyCredentialRequest?

    var authCompletionRoute: BitwardenShared.AppRoute?
    var isInAppExtension: Bool = true
    var uri: String?

    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential) {
        completeRegistrationRequestCalled = true
    }

    func didCancel() {
        didCancelCalled = true
    }

    func getRequestForFido2Creation() -> ASPasskeyCredentialRequest? {
        getRequestForFido2CreationResult
    }
}
