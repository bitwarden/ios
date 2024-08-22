// MARK: - RemoveMasterPasswordState

/// An object that defines the current state of a `RemoveMasterPasswordView`.
///
struct RemoveMasterPasswordState: Equatable {
    // MARK: Properties

    /// A flag indicating if the master password should be revealed or not.
    var isMasterPasswordRevealed = false

    /// The user's master password.
    var masterPassword: String = ""

    /// The organization's name.
    let organizationName: String
}
