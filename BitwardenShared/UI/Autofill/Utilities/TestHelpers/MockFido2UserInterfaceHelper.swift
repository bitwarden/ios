import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockFido2UserInterfaceHelper: Fido2UserInterfaceHelper {
    var checkUserResult: Result<BitwardenSdk.CheckUserResult, Error> = .success(
        BitwardenSdk.CheckUserResult(userPresent: true, userVerified: true)
    )
    var pickCredentialForAuthenticationResult: Result<BitwardenSdk.CipherViewWrapper, Error> = .success(
        BitwardenSdk.CipherViewWrapper(cipher: .fixture())
    )
    var pickedCredentialForCreationCalled = false
    var checkAndPickCredentialForCreationResult: Result<BitwardenSdk.CipherViewWrapper, Error> = .success(
        BitwardenSdk.CipherViewWrapper(cipher: .fixture())
    )
    var isVerificationEnabledResult = false
    var fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate?

    func checkUser(
        options: BitwardenSdk.CheckUserOptions,
        hint: BitwardenSdk.UiHint
    ) async throws -> BitwardenSdk.CheckUserResult {
        try checkUserResult.get()
    }

    func pickCredentialForAuthentication(
        availableCredentials: [BitwardenSdk.CipherView]
    ) async throws -> BitwardenSdk.CipherViewWrapper {
        try pickCredentialForAuthenticationResult.get()
    }

    func pickedCredentialForCreation(cipherResult: Result<BitwardenSdk.CipherView, any Error>) {
        pickedCredentialForCreationCalled = true
    }

    func checkUserAndPickCredentialForCreation(
        options: BitwardenSdk.CheckUserOptions,
        newCredential: BitwardenSdk.Fido2CredentialNewView
    ) async throws -> BitwardenSdk.CipherViewWrapper {
        try checkAndPickCredentialForCreationResult.get()
    }

    func isVerificationEnabled() async -> Bool {
        isVerificationEnabledResult
    }

    func setupDelegate(fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate) {
        self.fido2UserVerificationMediatorDelegate = fido2UserVerificationMediatorDelegate
    }
}
