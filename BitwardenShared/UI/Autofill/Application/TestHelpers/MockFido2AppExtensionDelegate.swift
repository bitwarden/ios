import AuthenticationServices
import Combine
import Foundation

@testable import BitwardenShared

@available(iOS 17.0, *)
class MockFido2AppExtensionDelegate: MockAppExtensionDelegate, Fido2AppExtensionDelegate {
    var completeAssertionRequestMocker = InvocationMocker<ASPasskeyAssertionCredential>()
    var completeRegistrationRequestMocker = InvocationMocker<ASPasskeyRegistrationCredential>()
    var extensionMode: AutofillExtensionMode = .configureAutofill
    var didAppearPublisher = CurrentValueSubject<Bool, Never>(false)
    var setUserInteractionRequiredCalled = false

    var flowWithUserInteraction: Bool = true

    func completeAssertionRequest(assertionCredential: ASPasskeyAssertionCredential) {
        completeAssertionRequestMocker.invoke(param: assertionCredential)
    }

    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential) {
        completeRegistrationRequestMocker.invoke(param: asPasskeyRegistrationCredential)
    }

    func getDidAppearPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>> {
        didAppearPublisher
            .eraseToAnyPublisher()
            .values
    }

    func setUserInteractionRequired() {
        setUserInteractionRequiredCalled = true
    }
}
