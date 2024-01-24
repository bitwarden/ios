// MARK: - VaultUnlockState

/// An object that defines the current state of a `VaultUnlockView`.
///
struct VaultUnlockState: Equatable {
    // MARK: - UnlockMethod

    /// The user information used to unlock the vault.
    ///
    enum UnlockMethod {
        /// Unlocking using the password.
        case password

        /// Unlocking using the PIN.
        case pin
    }

    // MARK: Properties

    /// The biometric auth status for the user.
    var biometricUnlockStatus: BiometricsUnlockStatus = .notAvailable

    /// The user's email for the active account.
    let email: String

    /// Whether the view is being displayed in the app extension.
    var isInAppExtension = false

    /// A flag indicating if the master password should be revealed or not.
    var isMasterPasswordRevealed = false

    /// Whether the pin is revealed.
    var isPinRevealed = false

    /// The master password provided by the user.
    var masterPassword: String = ""

    /// The PIN provided by the user.
    var pin: String = ""

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState

    /// The user information used to unlock the vault.
    var unlockMethod: UnlockMethod = .password

    /// A toast message to show in the view.
    var toast: Toast?

    /// Keeps track of the number of unsuccessful attempts to unlock the vault.
    var unsuccessfulUnlockAttemptsCount: Int = 0

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
        profileSwitcherState: ProfileSwitcherState = .empty()
    ) {
        self.init(
            email: account.profile.email,
            profileSwitcherState: profileSwitcherState,
            webVaultHost: account.settings.environmentUrls?.webVaultHost ?? Constants.defaultWebVaultHost
        )
    }
}
