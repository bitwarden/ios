import AuthenticationServices
import Foundation

@testable import BitwardenShared

@available(iOS 17.0, *)
class MockFido2AppExtensionDelegate: MockAppExtensionDelegate, Fido2AppExtensionDelegate {
    var completeRegistrationRequestMocker = InvocationMocker<ASPasskeyRegistrationCredential>()
    var extensionMode: AutofillExtensionMode = .configureAutofill

    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential) {
        completeRegistrationRequestMocker.invoke(param: asPasskeyRegistrationCredential)
    }
}
