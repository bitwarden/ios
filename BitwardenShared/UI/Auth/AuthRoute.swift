// MARK: - AuthRoute

/// A route to a specific screen in the authentication flow.
public enum AuthRoute: Equatable {
    /// A route to the create account screen.
    case createAccount

    /// A route to the enterprise single sign-on screen.
    case enterpriseSingleSignOn

    /// A route to the landing screen.
    case landing

    /// A route to the login screen.
    ///
    /// - Parameters:
    ///   - username: The username to display on the login screen.
    ///   - region: The region the user has selected for login.
    ///   - isLoginWithDeviceEnabled: A flag indicating if the "Login with device" button should be displayed in the
    ///                               login screen.
    case login(username: String, region: String, isLoginWithDeviceEnabled: Bool)

    /// A route to the login options screen.
    case loginOptions

    /// A route to the login with device screen.
    case loginWithDevice

    /// A route to the master password hint screen.
    case masterPasswordHint

    /// A route to the region selection screen.
    case regionSelection
}
