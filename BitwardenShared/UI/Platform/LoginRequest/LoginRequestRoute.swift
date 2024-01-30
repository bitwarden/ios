// MARK: - LoginRequestRoute

/// A route to specific screens in the login request view.
public enum LoginRequestRoute: Equatable, Hashable {
    /// A route to dismiss the screen currently presented modally.
    ///
    /// - Parameter action: The action to perform on dismiss.
    ///
    case dismiss(_ action: DismissAction? = nil)

    /// A route to the login request view.
    ///
    /// - Parameter loginRequest: The login request to show.
    ///
    case loginRequest(_ loginRequest: LoginRequest)
}
