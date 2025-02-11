// MARK: - UpdateMasterPasswordEffect

/// Effects that can be processed by a `UpdateMasterPasswordProcessor`.
enum UpdateMasterPasswordEffect: Equatable {
    /// The update master password view appeared on screen.
    case appeared

    /// The logout button was tapped.
    case logoutTapped

    /// The save button was tapped.
    case saveTapped
}
