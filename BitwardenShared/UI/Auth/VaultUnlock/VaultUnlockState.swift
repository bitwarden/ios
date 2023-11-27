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

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState

    /// The hostname of the web vault URL.
    let webVaultHost: String
}

extension VaultUnlockState {
    // MARK: Initialization

    /// Initialize `VaultUnlockState` for an account.
    ///
    /// - Parameters:
    ///   - account: The active account.
    ///   - profileSwitcherState: State for the profile switcher.
    ///
    init(
        account: Account,
        profileSwitcherState: ProfileSwitcherState = ProfileSwitcherState(
            accounts: [],
            activeAccountId: nil,
            isVisible: false,
            shouldAlwaysHideAddAccount: false
        )
    ) {
        self.init(
            email: account.profile.email,
            profileSwitcherState: profileSwitcherState,
            webVaultHost: account.settings.environmentUrls?.webVault?.host ?? Constants.defaultWebVaultHost
        )
    }
}
