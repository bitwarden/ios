import BitwardenKit
import BitwardenResources
@preconcurrency import BitwardenSdk

// MARK: - UpdateMasterPasswordState

/// An object that defines the current state of a `UpdateMasterPasswordView`.
///
struct UpdateMasterPasswordState: Equatable, Sendable {
    // MARK: Properties

    /// The current master password provided by the user.
    var currentMasterPassword: String = ""

    /// The reason why the user needs to update their master password.
    var forcePasswordResetReason: ForcePasswordResetReason?

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

    /// The master password policy in effect.
    var masterPasswordPolicy: MasterPasswordPolicyOptions?

    /// The retype of new master password provided by the user.
    var masterPasswordRetype: String = ""

    /// A scoring metric that represents the strength of the entered password. The score ranges from
    /// 0-4 (weak to strong password).
    var passwordStrengthScore: UInt8?

    // MARK: Computed Properties

    /// Whether the current password is required.
    var requireCurrentPassword: Bool {
        forcePasswordResetReason == .weakMasterPasswordOnLogin
    }

    /// The required text count for the password strength.
    let requiredPasswordCount = Constants.minimumPasswordCharacters

    /// The email of the user that is updating the account password.
    var userEmail: String = ""

    /// The message to display for why the user's password needs to be updated.
    var updateMasterPasswordWarning: String {
        forcePasswordResetReason == .weakMasterPasswordOnLogin
            ? Localizations.updateWeakMasterPasswordWarning
            : Localizations.updateMasterPasswordWarning
    }
}
