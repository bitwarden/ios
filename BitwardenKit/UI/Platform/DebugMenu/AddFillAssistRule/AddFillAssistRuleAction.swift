// MARK: - AddFillAssistRuleAction

/// Actions handled by the `AddFillAssistRuleProcessor`.
///
enum AddFillAssistRuleAction: Equatable {
    /// Dismiss the sheet.
    case dismiss

    /// The domain field text changed.
    case domainChanged(String)

    /// The password field id text changed.
    case passwordFieldIdChanged(String)

    /// The username field id text changed.
    case usernameFieldIdChanged(String)
}
