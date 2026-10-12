// MARK: - AddFillAssistRuleState

/// An object that defines the current state of the `AddFillAssistRuleView`.
///
struct AddFillAssistRuleState: Equatable {
    // MARK: Properties

    /// The bare hostname the rule applies to (e.g. `"example.com"`).
    var domain = ""

    /// The `id` attribute value of the password field (e.g. `"password"`).
    var passwordFieldId = ""

    /// The `id` attribute value of the username field (e.g. `"username"`).
    var usernameFieldId = ""
}
