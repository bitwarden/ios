/// An object that defines the current state of a `VaultUnlockView`.
///
struct VaultUnlockState: Equatable {
    // MARK: Properties

    /// The biometric auth status for the user.
    var biometricAuthStatus: BiometricAuthorizationStatus = .notDetermined

    /// A flag indicating if the user has selected biometric unlock in settings.
    var biometricUnlockEnabled: Bool = false

    var biometricUnlockString: String? {
        guard biometricUnlockEnabled else { return nil }
        switch biometricAuthStatus.biometricAuthenticationType {
        case .faceID:
            return Localizations.useFaceIDToUnlock
        case .touchID:
            return Localizations.useFingerprintToUnlock
        case .none:
            return nil
        }
    }

    /// The user's email for the active account.
    let email: String

    /// Whether the view is being displayed in the app extension.
    var isInAppExtension = false

    /// A flag indicating if the master password should be revealed or not.
    var isMasterPasswordRevealed = false

    /// The master password provided by the user.
    var masterPassword: String = ""

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState

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
