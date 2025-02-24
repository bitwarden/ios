// MARK: - VaultUnlockAction

/// Synchronous actions that can be handled by a `VaultUnlockProcessor`.
///
enum VaultUnlockAction: Equatable {
    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
