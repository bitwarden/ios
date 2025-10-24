// MARK: - UnlockPasskeyStatus

/// An object that defines the current state of the unlock passkey for an account.
///
struct UnlockPasskeyStatus: Equatable {
    // MARK: Properties

    /// The unlock passkey status for the user.
    let isUnlockPasskeyEnabled: Bool

    /// The associated user account.
    let userId: String
}
