import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockFido2UserVerificationMediator: Fido2UserVerificationMediator {
    var checkUserResult: Result<BitwardenSdk.CheckUserResult, Error> = .success(CheckUserResult(userPresent: false, userVerified: false))
    var isPreferredVerificationEnabledResult = false
    var setupDelegateCalled = false

    func checkUser(userVerificationPreference: BitwardenSdk.Verification, credential: BitwardenSdk.CipherView) async throws -> BitwardenSdk.CheckUserResult {
        try checkUserResult.get()
    }
    
    func isPreferredVerificationEnabled() -> Bool {
        isPreferredVerificationEnabledResult
    }
    
    func setupDelegate(fido2UserVerificationMediatorDelegate: any BitwardenShared.Fido2UserVerificationMediatorDelegate) {
        setupDelegateCalled = true
    }
}
