import AuthenticationServices
import BitwardenSharedMocks
import Testing

@testable import BitwardenShared

struct CredentialProviderModeTests {
    // MARK: Tests

    /// `generatePasswordRules` returns `nil` for modes other than `generatePasswordCredential`.
    @Test
    func generatePasswordRules_nonGeneratePasswordCredentialMode() {
        #expect(CredentialProviderMode.configureAutofill.generatePasswordRules == nil)
        #expect(CredentialProviderMode.autofillVaultList([]).generatePasswordRules == nil)
    }

    /// `generatePasswordRules` returns `passwordFieldPasswordRules` when it is non-nil.
    @Test
    func generatePasswordRules_prefersPasswordFieldRules() {
        let request = MockGeneratePasswordRequestProxy()
        request.passwordFieldPasswordRules = "minlength: 20;"
        request.passwordRulesFromQuirks = "minlength: 8;"
        let mode = CredentialProviderMode.generatePasswordCredential(request, userInteraction: true)
        #expect(mode.generatePasswordRules == "minlength: 20;")
    }

    /// `generatePasswordRules` falls back to `passwordRulesFromQuirks` when
    /// `passwordFieldPasswordRules` is `nil`.
    @Test
    func generatePasswordRules_fallsBackToQuirks() {
        let request = MockGeneratePasswordRequestProxy()
        request.passwordRulesFromQuirks = "minlength: 8;"
        let mode = CredentialProviderMode.generatePasswordCredential(request, userInteraction: true)
        #expect(mode.generatePasswordRules == "minlength: 8;")
    }

    /// `generatePasswordRules` returns `nil` when both rule sources are `nil`.
    @Test
    func generatePasswordRules_nilWhenBothSourcesNil() {
        let request = MockGeneratePasswordRequestProxy()
        let mode = CredentialProviderMode.generatePasswordCredential(request, userInteraction: true)
        #expect(mode.generatePasswordRules == nil)
    }

    /// `savePasswordRequestPassword` returns the password from the `savePasswordCredential`
    /// mode's request.
    @Test
    func savePasswordRequestPassword() {
        let mode = CredentialProviderMode.savePasswordCredential(
            MockSavePasswordRequestProxy(password: "new"),
            userInteraction: true,
        )
        #expect(mode.savePasswordRequestPassword == "new")
    }

    /// `savePasswordRequestPassword` returns `nil` for modes other than `savePasswordCredential`.
    @Test
    func savePasswordRequestPassword_nonSavePasswordCredentialMode() {
        #expect(CredentialProviderMode.configureAutofill.savePasswordRequestPassword == nil)
        #expect(CredentialProviderMode.autofillVaultList([]).savePasswordRequestPassword == nil)
    }

    /// `ASSavePasswordRequest`'s `password` is the password of the credential being saved.
    @Test
    @available(iOS 26.2, *)
    func savePasswordRequest_password() {
        let request = ASSavePasswordRequest(
            serviceIdentifier: ASCredentialServiceIdentifier(identifier: "https://example.com", type: .URL),
            credential: ASPasswordCredential(user: "user", password: "new"),
            title: "Example",
            sessionID: "session-1",
            event: .userInitiated,
        )
        #expect(request.password == "new")
    }
}
