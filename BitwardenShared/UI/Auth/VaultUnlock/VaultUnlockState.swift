/// An object that defines the current state of a `VaultUnlockView`.
///
struct VaultUnlockState: Equatable {
    // MARK: Properties

    /// The user's email for the active account.
    let email: String

    /// A flag indicating if the master password should be revealed or not.
    var isMasterPasswordRevealed = false

    /// The master password provided by the user.
    var masterPassword: String = ""

    /// The hostname of the web vault URL.
    let webVaultHost: String
}

extension VaultUnlockState {
    // MARK: Initialization

    /// Initialize `VaultUnlockState` for an account.
    ///
    /// - Parameter account: The active account.
    ///
    init(account: Account) {
        self.init(
            email: account.profile.email,
            webVaultHost: account.settings.environmentUrls?.webVault?.host ?? Constants.defaultWebVaultHost
        )
    }
}
