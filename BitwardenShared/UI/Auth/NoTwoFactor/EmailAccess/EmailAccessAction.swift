// MARK: - EmailAccessAction

/// Actions that can be processed by a `EmailAccessProcessor`.
///
enum EmailAccessAction: Equatable, Sendable {
    case canAccessEmailChanged(Bool)

    /// The current page index has changed.
    case currentPageIndexChanged(Int)
}
