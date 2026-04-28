import BitwardenKit

// MARK: - AutoFillAction

/// Actions emitted by the `AutoFillView`.
///
enum AutoFillAction: Equatable {
    /// The app extension button was tapped.
    case appExtensionTapped

    /// Clears the URL.
    case clearUrl

    /// The default URI match type was changed.
    case defaultUriMatchTypeChanged(UriMatchType)

    /// The user tapped to learn more about AutoFill.
    case learnMoreAboutAutofillTapped

    /// The password auto-fill button was tapped.
    case passwordAutoFillTapped

    /// The copy TOTP automatically toggle value changed.
    case toggleCopyTOTPToggle(Bool)

    /// A toast was shown or hidden.
    case toastShown(Toast?)
}
