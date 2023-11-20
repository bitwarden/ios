// MARK: - AutoFillAction

/// Actions emitted by the `AutoFillView`.
///
enum AutoFillAction: Equatable {
    /// The copy TOTP automatically toggle value changed.
    case toggleCopyTOTPToggle(Bool)
}
