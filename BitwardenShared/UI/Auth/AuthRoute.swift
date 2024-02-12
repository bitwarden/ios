import Foundation

// MARK: - AuthRoute

/// A route to a specific screen in the authentication flow.
public enum AuthRoute: Equatable {
    /// A route to display the specified alert.
    ///
    /// - Parameter alert: The alert to display.
    case alert(_ alert: Alert)

    /// A route to the captcha screen.
    case captcha(url: URL, callbackUrlScheme: String)

    /// Dismisses the auth flow.
    case complete

    /// A route to the create account screen.
    case createAccount

    /// A route that dismisses a presented sheet.
    case dismiss

    /// A route to the enterprise single sign-on screen.
    ///
    /// - Parameter email: The user's email.
    ///
    case enterpriseSingleSignOn(email: String)

    /// A route to the landing screen.
    case landing

    /// A route to the login screen.
    ///
    /// - Parameters:
    ///   - username: The username to display on the login screen.
    ///   - region: The region the user has selected for login.
    ///   - isLoginWithDeviceVisible: A flag indicating if the "Login with device" button should be displayed in the
    ///                               login screen.
    case login(username: String, region: RegionType, isLoginWithDeviceVisible: Bool)

    /// A route to the login with device screen.
    ///
    /// - Parameter email: The user's email.
    ///
    case loginWithDevice(email: String)

    /// A route to the master password hint screen for the provided username.
    ///
    /// - Parameter username: The username to display on the password hint screen.
    case masterPasswordHint(username: String)

    /// A route to the update master password view.
    case updateMasterPassword

    /// A route to the self-hosted settings view.
    case selfHosted

    /// A route to the single sign on WebAuth screen.
    ///
    /// - Parameters:
    ///   - callbackUrlScheme: The callback url scheme for this application.
    ///   - state: The string that the result will have to match.
    ///   - url: The url to present to the web auth session.
    ///
    case singleSignOn(callbackUrlScheme: String, state: String, url: URL)

    /// A route to the two-factor authentication view.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - unlockMethod: The method used to unlock the vault after two-factor completes successfully.
    ///   - authMethodsData: The data on the available auth methods.
    ///
    case twoFactor(
        _ email: String,
        _ unlockMethod: TwoFactorUnlockMethod?,
        _ authMethodsData: AuthMethodsData
    )

    /// A route to the unlock vault screen.
    ///
    /// - Parameters:
    ///   - account: The account to unlock the vault for.
    ///   - animated: Whether to animate the transition to the view.
    ///   - attemptAutomaticBiometricUnlock: If `true` and biometric unlock is enabled/available,
    ///     the processor should attempt an automatic biometric unlock.
    ///   - didSwitchAccountAutomatically: A flag indicating if the active account was switched automatically.
    ///
    case vaultUnlock(
        Account,
        animated: Bool,
        attemptAutomaticBiometricUnlock: Bool,
        didSwitchAccountAutomatically: Bool
    )
}
