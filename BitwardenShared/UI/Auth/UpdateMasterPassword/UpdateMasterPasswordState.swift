// MARK: - UpdateMasterPasswordState

/// An object that defines the current state of a `UpdateMasterPasswordView`.
///
struct UpdateMasterPasswordState: Equatable {
    // MARK: Properties

    /// The current master password provided by the user.
    var currentMasterPassword: String = ""

    /// A flag indicating if the current master password should be revealed or not.
    var isCurrentMasterPasswordRevealed: Bool = false

    /// A flag indicating if the new master password should be revealed or not.
    var isMasterPasswordRevealed: Bool = false

    /// A flag indicating if the retype of new master password should be revealed or not.
    var isMasterPasswordRetypeRevealed: Bool = false

    /// The new master password provided by the user.
    var masterPassword: String = ""

    /// The new master password hint provided by the user.
    var masterPasswordHint: String = ""

    /// The retype of new master password provided by the user.
    var masterPasswordRetype: String = ""
}
