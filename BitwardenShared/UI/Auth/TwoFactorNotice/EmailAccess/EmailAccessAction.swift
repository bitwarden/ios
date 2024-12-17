// MARK: - EmailAccessAction

/// Actions that can be processed by a `EmailAccessProcessor`.
///
enum EmailAccessAction: Equatable, Sendable {
    /// The user changed the toggle for being able to access email.
    case canAccessEmailChanged(Bool)
}
