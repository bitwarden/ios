import Foundation

// MARK: - AuthRoute

/// A route to a specific screen in the authentication flow.
public enum AuthRoute: Equatable {
    /// A route to the captcha screen.
    case captcha(url: URL, callbackUrlScheme: String)

    /// Dismisses the auth flow.
    case complete

    /// A route to the create account screen.
    case createAccount

    /// A route to complete registration screen.
    /// - Parameters:
    ///    - userEmail: The user's email.
    ///    - emailVerificationToken: Token needed to complete registration.
    ///
    case completeRegistration(emailVerificationToken: String, userEmail: String)

    /// A route that dismisses a presented sheet.
    case dismiss

    /// A route that dismisses only the presented sheet.
    case dismissPresented

    /// A route that triggers the duo 2FA flow.
    ///  Requires that any `context` provided to the coordinator conforms to `DuoAuthenticationFlowDelegate`.
    case duoAuthenticationFlow(_ authURL: URL)

    /// A route to the enterprise single sign-on screen.
    ///
    /// - Parameter email: The user's email.
    ///
    case enterpriseSingleSignOn(email: String)

    /// A route to the landing screen.
    case landing

    /// A route to the login screen.
    ///
    /// - Parameter username: The username to display on the login screen.
    ///
    case login(username: String)

    /// A route to the login decryption options screen.
    ///
    /// - Parameter organizationIdentifier: The organization's identifier.
    ///
    case showLoginDecryptionOptions(organizationIdentifier: String)

    /// A route to start registration screen.
    ///
    case startRegistration

    /// A route to the login with device screen.
    ///
    /// - Parameters:
    ///    - email: The user's email.
    ///    - authRequestType: The auth request type.
    ///    - isAuthenticated: If the user came from sso and is already authenticated
    ///
    case loginWithDevice(email: String, authRequestType: AuthRequestType, isAuthenticated: Bool)

    /// A route to the master password hint screen for the provided username.
    ///
    /// - Parameter username: The username to display on the password hint screen.
    case masterPasswordHint(username: String)

    /// A route to the self-hosted settings view.
    ///
    /// - Parameter currentRegion: The user's region type prior to navigating to the self-hosted view.
    case selfHosted(currentRegion: RegionType)

    /// A route to the set master password view.
    ///
    /// - Parameter organizationIdentifier: The organization's identifier.
    ///
    case setMasterPassword(organizationIdentifier: String)

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
    ///   - orgIdentifier: The identifier for the organization used in the SSO flow
    ///
    case twoFactor(
        _ email: String,
        _ unlockMethod: TwoFactorUnlockMethod?,
        _ authMethodsData: AuthMethodsData,
        _ orgIdentifier: String?
    )

    /// A route to the update master password view.
    case updateMasterPassword

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

    /// A route to the WebAuthn two factor authentication.
    ///
    /// - Parameters:
    ///   - rpId: Identifier for the relying party.
    ///   - challenge: Challenge sent to be solve by an authenticator.
    ///   - credentialsIds: Identifiers for the allowed credentials to be used to solve the challenge
    ///   - userVerificationPreference: specifies which type of user verification is necessary
    ///
    case webAuthn(
        rpid: String,
        challenge: Data,
        allowCredentialIDs: [Data],
        userVerificationPreference: String
    )
}
