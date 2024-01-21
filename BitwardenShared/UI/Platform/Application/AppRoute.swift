// MARK: - AppRoute

/// A top level route from the initial screen of the app to anywhere in the app.
///
public enum AppRoute: Equatable {
    /// A route to the authentication flow.
    case auth(AuthRoute)

    /// A route to the extension setup interface.
    case extensionSetup(ExtensionSetupRoute)

    /// A route to the tab interface.
    case tab(TabRoute)

    /// A route to the vault interface.
    case vault(VaultRoute)
}
