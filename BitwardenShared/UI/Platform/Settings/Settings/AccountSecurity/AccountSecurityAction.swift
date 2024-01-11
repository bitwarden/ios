import Foundation

// MARK: AccountSecurityAction

/// Actions handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityAction {
    /// Clears the two step login URL after the web app has been opened.
    case clearTwoStepLoginUrl

    /// The delete account button was pressed.
    case deleteAccountPressed

    /// The logout button was pressed.
    case logout

    /// The session timeout action has changed.
    case sessionTimeoutActionChanged(SessionTimeoutAction)

    /// The session timeout value has changed.
    case sessionTimeoutValueChanged(SessionTimeoutValue)

    /// Sets the custom session timeout value.
    case customTimeoutValueChanged(TimeInterval)

    /// Approve login requests was toggled.
    case toggleApproveLoginRequestsToggle(Bool)

    /// Unlock with face ID was toggled.
    case toggleUnlockWithFaceID(Bool)

    /// Unlock with pin code was toggled.
    case toggleUnlockWithPINCode(Bool)

    /// Unlock with touch ID was toggled.
    case toggleUnlockWithTouchID(Bool)

    /// The two step login button was pressed.
    case twoStepLoginPressed
}
