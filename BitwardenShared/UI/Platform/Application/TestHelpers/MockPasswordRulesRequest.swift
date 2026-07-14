@testable import BitwardenShared

class MockPasswordRulesRequest: GeneratePasswordRequestProxy {
    var passwordFieldPasswordRules: String?
    var passwordRulesFromQuirks: String?

    init(
        passwordFieldPasswordRules: String? = nil,
        passwordRulesFromQuirks: String? = nil,
    ) {
        self.passwordFieldPasswordRules = passwordFieldPasswordRules
        self.passwordRulesFromQuirks = passwordRulesFromQuirks
    }
}
