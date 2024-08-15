// MARK: - MasterPasswordGeneratorAction

/// Actions that can be processed by a `MasterPasswordGeneratorProcessor`.
///
enum MasterPasswordGeneratorAction: Equatable {
    /// The `MasterPasswordGeneratorView` was dismissed.
    case dismiss

    /// The value for the master password was changed.
    case masterPasswordChanged(String)

    /// The button to learn more about preventing account lock was tapped.
    case preventAccountLock

    /// The save button was tapped.
    case save
}
