/// An enumeration of methods used to unlock the user's vault after two-factor authentication
/// completes successfully.
///
public enum TwoFactorUnlockMethod: Equatable, Sendable {
    /// The vault should be unlocked with the response from logging in with another device.
    case loginWithDevice(key: String, masterPasswordHash: String?, privateKey: String)

    /// The vault should be unlocked with the user's master password.
    case password(String)
}
