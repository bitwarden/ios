// MARK: - AccountSecurityState

/// An object that defines the current state of the `AccountSecurityView`.
///
struct AccountSecurityState: Equatable {
    /// Whether the approve login requests toggle is on.
    var isApproveLoginRequestsToggleOn: Bool = false

    /// Whether the unlock with face ID toggle is on.
    var isUnlockWithFaceIDOn: Bool = false

    /// Whether the unlock with pin code toggle is on.
    var isUnlockWithPINCodeOn: Bool = false

    /// Whether the unlock with touch ID toggle is on.
    var isUnlockWithTouchIDToggleOn: Bool = false
}
