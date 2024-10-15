// MARK: - ImportLoginsEffect

/// Effects handled by the `ImportLoginsProcessor`.
///
enum ImportLoginsEffect: Equatable {
    /// The view appeared on screen.
    case appeared

    /// The import logins button was tapped.
    case importLoginsLater
}
