import BitwardenSdk

// MARK: - PasswordHealthAction

/// Actions handled by the `PasswordHealthProcessor`.
///
enum PasswordHealthAction: Equatable {
    /// The user tapped on a cipher item in the list.
    case itemPressed(CipherListView)
}
