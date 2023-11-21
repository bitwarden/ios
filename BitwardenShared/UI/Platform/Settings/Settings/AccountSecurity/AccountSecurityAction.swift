// MARK: AccountSecurityAction

/// Actions handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityAction {
    /// The delete account button was pressed.
    case deleteAccountPressed

    /// The logout button was pressed.
    case logout

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
