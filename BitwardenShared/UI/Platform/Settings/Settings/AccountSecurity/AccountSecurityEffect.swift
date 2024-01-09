// MARK: - AccountSecurityEffect

/// Effects handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityEffect {
    case appeared

    /// The user's vault was locked.
    case lockVault
}
