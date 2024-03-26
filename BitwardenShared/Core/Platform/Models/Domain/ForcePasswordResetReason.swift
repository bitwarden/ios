/// An enum describing the reasoning for why a forced password reset may be required.
///
enum ForcePasswordResetReason: Int, Codable, Equatable, Hashable {
    /// Occurs when an organization admin forces a user to reset their password.
    case adminForcePasswordReset

    /// Occurs when a user logs in with a master password that does not meet an organization's
    /// master password policy that is enforced on login.
    case weakMasterPasswordOnLogin

    /// Occurs when a TDE user without a password obtains the password reset permission.
    /// Set post login & decryption client side and by server in sync (to catch logged in users).
    case tdeUserWithoutPasswordHasPasswordResetPermission
}
