// MARK: ImportLoginsRoute

/// A route to a screen within the import logins flow.
///
public enum ImportLoginsRoute: Equatable {
    /// A route to dismiss the screen currently presented modally.
    case dismiss

    /// A route to the import logins screen.
    case importLogins(ImportLoginsState.Mode)

    /// A route to the import logins success screen.
    case importLoginsSuccess
}
