// MARK: - DebugStateService

/// A service providing account state manipulation to support testing scenarios.
///
public protocol DebugStateService: AnyObject { // sourcery: AutoMockable
    /// Adds or replaces a Fill Assist rule for the active account's cached rules, for testing
    /// against custom pages without waiting for a real forms-map sync.
    ///
    /// - Parameters:
    ///   - domain: The bare hostname the rule applies to (e.g. `"example.com"`).
    ///   - usernameFieldId: The `id` attribute value of the username field (e.g. `"username"`).
    ///   - passwordFieldId: The `id` attribute value of the password field (e.g. `"password"`).
    ///
    func addFillAssistDebugRule(
        domain: String,
        usernameFieldId: String,
        passwordFieldId: String,
    ) async throws

    /// Clears the active account's cached Fill Assist rules and their integrity fingerprint,
    /// the same cleanup that runs automatically on logout.
    func clearFillAssistCache() async throws

    /// Clears `userDecryptionOptions.masterPasswordUnlock` on the active account's cached profile.
    func clearMasterPasswordUnlockForActiveAccount() async throws
}
