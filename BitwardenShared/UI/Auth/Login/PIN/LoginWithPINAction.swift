// MARK: - LoginWithPINAction

/// An enumeration of actions handled by the `LoginWithPINProcessor`.
/// 
enum LoginWithPINAction {
    /// The PIN in the text field changed.
    case pinChanged(String)

    /// A forwarded profile switcher action.
    case profileSwitcherAction(ProfileSwitcherAction)

    /// Shows or hides the PIN in the text field.
    case showPIN(Bool)
}
