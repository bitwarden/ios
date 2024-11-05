// MARK: - MasterPasswordGuidanceAction

/// Actions that can be processed by a `MasterPasswordGuidanceProcessor`.
///
enum MasterPasswordGuidanceAction: Equatable {
    /// The `MasterPasswordGuidanceView` was dismissed.
    case dismiss

    /// The generate password button was pressed.
    case generatePasswordPressed
}
