import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

class MockFido2UserInterfaceHelper: Fido2UserInterfaceHelper {
    var checkUserCalled = false
    var checkUserResult: Result<BitwardenSdk.CheckUserResult, Error> = .success(
        BitwardenSdk.CheckUserResult(userPresent: true, userVerified: true)
    )
    var credentialsForAuthenticationSubject = CurrentValueSubject<[BitwardenSdk.CipherView]?, Error>(
        nil
    )
    var fido2CreationOptions: BitwardenSdk.CheckUserOptions?
    var fido2CredentialNewView: BitwardenSdk.Fido2CredentialNewView?
    var pickCredentialForAuthenticationResult: Result<BitwardenSdk.CipherViewWrapper, Error> = .success(
        BitwardenSdk.CipherViewWrapper(cipher: .fixture())
    )
    var pickedCredentialForAuthenticationMocker = InvocationMocker<
        Result<CipherView, any Error>
    >()
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
    var fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate?

    func availableCredentialsForAuthenticationPublisher() -> AnyPublisher<[BitwardenSdk.CipherView]?, Error> {
        credentialsForAuthenticationSubject.eraseToAnyPublisher()
    }

    func checkUser(
        options: BitwardenSdk.CheckUserOptions,
        hint: BitwardenSdk.UiHint
    ) async throws -> BitwardenSdk.CheckUserResult {
        checkUserCalled = true
        return try checkUserResult.get()
    }

    func checkUser(
        userVerificationPreference: BitwardenSdk.Verification,
        credential: BitwardenSdk.CipherView,
        shouldThrowEnforcingRequiredVerification: Bool
    ) async throws -> BitwardenSdk.CheckUserResult {
        checkUserCalled = true
        return try checkUserResult.get()
    }

    func pickCredentialForAuthentication(
        availableCredentials: [BitwardenSdk.CipherView]
    ) async throws -> BitwardenSdk.CipherViewWrapper {
        try pickCredentialForAuthenticationResult.get()
    }

    func pickedCredentialForAuthentication(result: Result<CipherView, any Error>) {
        pickedCredentialForAuthenticationMocker.invoke(param: result)
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

    func setupDelegate(fido2UserInterfaceHelperDelegate: any BitwardenShared.Fido2UserInterfaceHelperDelegate) {
        self.fido2UserInterfaceHelperDelegate = fido2UserInterfaceHelperDelegate
    }
}
