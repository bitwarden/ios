// MARK: - AppRoute

/// A top level route from the initial screen of the app to anywhere in the app.
///
public enum AppRoute: Equatable {
    /// A route to the authentication flow.
    case auth(AuthRoute)
}
