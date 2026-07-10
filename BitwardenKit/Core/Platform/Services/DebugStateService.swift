// MARK: - DebugStateService

/// A service providing account state manipulation to support testing scenarios.
///
public protocol DebugStateService: AnyObject { // sourcery: AutoMockable
    /// Clears `userDecryptionOptions.masterPasswordUnlock` on the active account's cached profile.
    func clearMasterPasswordUnlockForActiveAccount() async throws
}
