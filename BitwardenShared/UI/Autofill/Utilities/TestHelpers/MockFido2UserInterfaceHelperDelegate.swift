import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockFido2UserInterfaceHelperDelegate:
    MockFido2UserVerificationMediatorDelegate, Fido2UserInterfaceHelperDelegate {
    var isAutofillingFromList: Bool = false
}
