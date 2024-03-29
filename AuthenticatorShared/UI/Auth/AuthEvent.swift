// MARK: - AuthEvent

/// An event to be handled by a Router tasked with producing `AuthRoute`s.
///
public enum AuthEvent: Equatable {
    /// When the app starts
    case didStart
}
