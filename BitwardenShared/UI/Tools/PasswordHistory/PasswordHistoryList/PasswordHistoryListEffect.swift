// MARK: - PasswordHistoryListEffect

/// Effects that can be processed by a `PasswordHistoryListProcessor`.
///
enum PasswordHistoryListEffect {
    /// The generator history appeared on screen.
    case appeared

    /// The clear button was tapped to clear the list of passwords.
    case clearList
}
