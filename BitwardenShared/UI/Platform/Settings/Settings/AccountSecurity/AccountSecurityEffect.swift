// MARK: - AccountSecurityEffect

/// Effects handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityEffect {
    /// The user's vault was locked.
    case lockVault(userId: String)
}
