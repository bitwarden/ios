// MARK: - AccountSecurityEffect

/// Effects handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityEffect {
    /// The view has appeared.
    case appeared

    /// The user's vault was locked.
    case lockVault
}
