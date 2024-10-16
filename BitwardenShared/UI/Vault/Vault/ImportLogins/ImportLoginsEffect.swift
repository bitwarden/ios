// MARK: - ImportLoginsEffect

/// Effects handled by the `ImportLoginsProcessor`.
///
enum ImportLoginsEffect: Equatable {
    /// Advance to the next page of instructions.
    case advanceNextPage

    /// The view appeared on screen.
    case appeared

    /// The import logins button was tapped.
    case importLoginsLater
}
