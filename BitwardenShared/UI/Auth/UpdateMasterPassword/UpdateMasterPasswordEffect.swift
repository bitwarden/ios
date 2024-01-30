// MARK: - UpdateMasterPasswordEffect

/// Effects that can be processed by a `UpdateMasterPasswordView`.
enum UpdateMasterPasswordEffect: Equatable {
    /// The update master password view appeared on screen.
    case appeared

    /// The logout button was pressed.
    case logoutPressed

    /// The submit button was pressed.
    case submitPressed
}
