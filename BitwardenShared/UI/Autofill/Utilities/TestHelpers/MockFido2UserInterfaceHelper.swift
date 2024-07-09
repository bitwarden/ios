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
    var pickedCredentialForCreationMocker = InvocationMocker<
        Result<CheckUserAndPickCredentialForCreationResult, any Error>
    >()
    var checkAndPickCredentialForCreationResult: Result<
        BitwardenSdk.CheckUserAndPickCredentialForCreationResult,
        Error
    > = .success(
        BitwardenSdk.CheckUserAndPickCredentialForCreationResult(
            cipher: CipherViewWrapper(cipher: .fixture()),
            checkUserResult: CheckUserResult(userPresent: true, userVerified: true)
        )
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

    func pickedCredentialForCreation(
        result: Result<BitwardenSdk.CheckUserAndPickCredentialForCreationResult, any Error>
    ) {
        pickedCredentialForCreationMocker.invoke(param: result)
    }

    func checkUserAndPickCredentialForCreation(
        options: BitwardenSdk.CheckUserOptions,
        newCredential: BitwardenSdk.Fido2CredentialNewView
    ) async throws -> BitwardenSdk.CheckUserAndPickCredentialForCreationResult {
        try checkAndPickCredentialForCreationResult.get()
    }

    func isVerificationEnabled() async -> Bool {
        isVerificationEnabledResult
    }

    func setupDelegate(fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate) {
        self.fido2UserVerificationMediatorDelegate = fido2UserVerificationMediatorDelegate
    }
}
