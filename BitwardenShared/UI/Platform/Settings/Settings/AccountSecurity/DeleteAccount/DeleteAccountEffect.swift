// MARK: - DeleteAccountEffect

/// Effects handled by the `DeleteAccountProcessor`.
///
enum DeleteAccountEffect {
    /// The delete account button was pressed.
    case deleteAccount

    /// Any initial data for the view should be loaded.
    case loadData
}
