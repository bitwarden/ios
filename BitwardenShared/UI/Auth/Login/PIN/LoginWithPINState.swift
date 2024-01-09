// MARK: - LoginWithPINState

/// An object that defines the current state of a `LoginWithPINView`.
///
struct LoginWithPINState {
    /// Whether the PIN is visible.
    var isPINVisible: Bool = false

    /// The user's PIN.
    var pinCode: String = ""

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState = .empty()
}
