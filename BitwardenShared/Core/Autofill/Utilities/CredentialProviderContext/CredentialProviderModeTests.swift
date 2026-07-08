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
        let request = MockGeneratePasswordRulesRequest(
            passwordFieldPasswordRules: "minlength: 20;",
            passwordRulesFromQuirks: "minlength: 8;",
        )
        let mode = CredentialProviderMode.generatePasswordCredential(request, userInteraction: true)
        #expect(mode.generatePasswordRules == "minlength: 20;")
    }

    /// `generatePasswordRules` falls back to `passwordRulesFromQuirks` when
    /// `passwordFieldPasswordRules` is `nil`.
    @Test
    func generatePasswordRules_fallsBackToQuirks() {
        let request = MockGeneratePasswordRulesRequest(
            passwordFieldPasswordRules: nil,
            passwordRulesFromQuirks: "minlength: 8;",
        )
        let mode = CredentialProviderMode.generatePasswordCredential(request, userInteraction: true)
        #expect(mode.generatePasswordRules == "minlength: 8;")
    }

    /// `generatePasswordRules` returns `nil` when both rule sources are `nil`.
    @Test
    func generatePasswordRules_nilWhenBothSourcesNil() {
        let request = MockGeneratePasswordRulesRequest(
            passwordFieldPasswordRules: nil,
            passwordRulesFromQuirks: nil,
        )
        let mode = CredentialProviderMode.generatePasswordCredential(request, userInteraction: true)
        #expect(mode.generatePasswordRules == nil)
    }
}

// MARK: - MockGeneratePasswordRulesRequest

private struct MockGeneratePasswordRulesRequest: GeneratePasswordRequestProxy {
    var passwordFieldPasswordRules: String?
    var passwordRulesFromQuirks: String?
}
