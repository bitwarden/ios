// MARK: - DeleteAccountState

/// An object that defines the current state of a `DeleteAccountView`.
///
struct DeleteAccountState: Equatable {
    // MARK: Properties

    /// Whether the form to delete the account is showed.
    var shouldPreventUserFromDeletingAccount = false
}
