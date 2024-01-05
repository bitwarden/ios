// MARK: - AutoFillAction

/// Actions emitted by the `AutoFillView`.
///
enum AutoFillAction: Equatable {
    /// The app extension button was tapped.
    case appExtensionTapped

    /// The password auto-fill button was tapped.
    case passwordAutoFillTapped

    /// The copy TOTP automatically toggle value changed.
    case toggleCopyTOTPToggle(Bool)
}
