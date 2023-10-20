/// An object that defines the current state of a `VaultUnlockView`.
///
struct VaultUnlockState: Equatable {
    // MARK: Properties

    /// The user's email for the active account.
    var email: String?

    /// A flag indicating if the master password should be revealed or not.
    var isMasterPasswordRevealed = false

    /// The master password provided by the user.
    var masterPassword: String = ""

    /// The hostname of the web vault URL.
    var webVaultHost: String?
}
