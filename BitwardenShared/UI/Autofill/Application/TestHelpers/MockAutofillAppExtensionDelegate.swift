import AuthenticationServices
import Combine
import Foundation
import TestHelpers

@testable import BitwardenShared

@available(iOS 17.0, *)
class MockAutofillAppExtensionDelegate: MockAppExtensionDelegate, AutofillAppExtensionDelegate {
    var completeAssertionRequestMocker = InvocationMocker<ASPasskeyAssertionCredential>()
    var completeOTPRequestCodeCalled: String?
    var completeRegistrationRequestMocker = InvocationMocker<ASPasskeyRegistrationCredential>()
    var completeTextRequestTextToInsert: String?
    var extensionMode: AutofillExtensionMode = .configureAutofill
    var didAppearPublisher = CurrentValueSubject<Bool, Never>(false)
    var setUserInteractionRequiredCalled = false

    var flowWithUserInteraction: Bool = true

    func completeAssertionRequest(assertionCredential: ASPasskeyAssertionCredential) {
        completeAssertionRequestMocker.invoke(param: assertionCredential)
    }

    func completeOTPRequest(code: String) {
        completeOTPRequestCodeCalled = code
    }

    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential) {
        completeRegistrationRequestMocker.invoke(param: asPasskeyRegistrationCredential)
    }

    @available(iOSApplicationExtension 18.0, *)
    func completeTextRequest(text: String) {
        completeTextRequestTextToInsert = text
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
