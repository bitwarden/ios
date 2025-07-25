import BitwardenResources

// MARK: - LoginWithDeviceState

/// An object that defines the current state of the `LoginWithDeviceView`.
///
struct LoginWithDeviceState: Equatable, Sendable {
    /// The user's email.
    var email = ""

    /// The fingerprint phrase.
    var fingerprintPhrase: String?

    /// If user comes from SSO flow and is already authenticated
    var isAuthenticated: Bool = false

    /// The id of the login request.
    var requestId: String?

    /// The id of the login request.
    var requestType: AuthRequestType = .authenticateAndUnlock

    // MARK: Computed Properties

    /// The explanation text based on requestType
    var explanationText: String {
        switch requestType {
        case .adminApproval:
            Localizations.yourRequestHasBeenSentToYourAdmin
        case .authenticateAndUnlock:
            Localizations.aNotificationHasBeenSentToYourDevice +
                .newLine +
                Localizations.pleaseMakeSureYourVaultIsUnlockedAndTheFingerprintPhraseMatchesOnTheOtherDevice
        }
    }

    /// If the resend notification should be visible to the user
    var isResendNotificationVisible: Bool { requestType == AuthRequestType.authenticateAndUnlock }

    /// Navigation bar text based on requestType
    var navBarText: String {
        switch requestType {
        case .adminApproval:
            Localizations.logInInitiated
        case .authenticateAndUnlock:
            Localizations.logInWithDevice
        }
    }

    /// Page title text based on requestType
    var titleText: String {
        switch requestType {
        case .adminApproval:
            Localizations.adminApprovalRequested
        case .authenticateAndUnlock:
            Localizations.logInInitiated
        }
    }
}
