// MARK: - GlobalModalRoute

/// A route to specific screens in global modals.
public enum GlobalModalRoute: Equatable, Hashable {
    /// A route to dismiss the screen currently presented modally.
    ///
    /// - Parameter action: The action to perform on dismiss.
    ///
    case dismissWithAction(_ action: DismissAction? = nil)

    /// A route to show the sync with browser screen.
    ///
    /// - Parameter vaultUrl: The vault URL from the SSO cookie config, used to construct
    ///   the browser redirect URL.
    ///
    case syncWithBrowser(vaultUrl: String)
}
