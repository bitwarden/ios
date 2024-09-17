// MARK: - AppRoute

/// A top level route from the initial screen of the app to anywhere in the app.
///
public enum AppRoute: Equatable {
    /// A route to the authentication flow.
    case auth(AuthRoute)

    /// A route to the extension setup interface.
    case extensionSetup(ExtensionSetupRoute)

    /// A route to show a login request.
    case loginRequest(LoginRequest)

    /// A route to the send interface.
    case sendItem(SendItemRoute)

    /// A route to the tab interface.
    case tab(TabRoute)

    /// A route to the vault interface.
    case vault(VaultRoute)

    /// A route to the debug menu.
    case showDebugMenu
}

public enum AppEvent: Equatable {
    /// When the user logs out from an account.
    ///
    /// - Parameters:
    ///   - userId: The userId of the account that was logged out.
    ///   - userInitiated: Did a user action trigger the account switch?
    ///
    case didLogout(userId: String, userInitiated: Bool)

    /// When the app has started.
    case didStart

    /// When an account has timed out.
    case didTimeout(userId: String)

    /// Allows setting a route that should be navigated to after the user's vault is unlocked.
    case setAuthCompletionRoute(AppRoute)
}
