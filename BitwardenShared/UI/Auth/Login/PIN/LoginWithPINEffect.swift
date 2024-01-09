// MARK: - LoginWithPINEffect

/// An enumeration of effects handled by the `LoginWithPINProcessor`.
///
enum LoginWithPINEffect: Equatable {
    /// The view has appeared
    case appeared

    /// The logout button was pressed.
    case logout

    /// A `ProfileSwitcherEffect`.
    case profileSwitcher(ProfileSwitcherEffect)

    /// The unlock button was pressed.
    case unlockWithPIN
}
