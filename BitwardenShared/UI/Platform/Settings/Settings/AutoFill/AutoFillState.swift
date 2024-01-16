// MARK: - AutoFillState

/// An object that defines the current state of the `AutoFillView`.
///
struct AutoFillState {
    /// The default URI match type.
    var defaultUriMatchType: UriMatchType = .domain

    /// Whether or not the copy TOTP automatically toggle is on.
    var isCopyTOTPToggleOn: Bool = false
}
