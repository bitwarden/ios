import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - AutoFillState

/// An object that defines the current state of the `AutoFillView`.
///
struct AutoFillState {
    // MARK: Properties

    /// The state of the badges in the settings tab.
    var badgeState: SettingsBadgeState?

    /// The default URI match type.
    var defaultUriMatchType: UriMatchType = .domain

    /// Whether autofill is turned on, or `nil` if it hasn't been determined yet.
    var isAutofillEnabled: Bool?

    /// Whether the autofill off action card feature flag is enabled.
    var isAutofillOffActionCardEnabled: Bool = false

    /// Whether or not the copy TOTP automatically toggle is on.
    var isCopyTOTPToggleOn: Bool = false

    /// Whether the Fill Assist toggle is on.
    var isFillAssistEnabled: Bool = false

    /// Whether the Fill Assist feature flag is enabled.
    var isFillAssistFeatureFlagEnabled: Bool = false

    /// Whether to show the password autofill row.
    var shouldShowPasswordAutofill: Bool = false

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    // MARK: Computed Properties

    /// Whether the set up autofill action card, driven by the user's autofill setup progress,
    /// should be shown. This is replaced by the autofill off action card when that feature flag
    /// is enabled.
    var shouldShowAutofillActionCard: Bool {
        guard !isAutofillOffActionCardEnabled,
              let badgeState,
              badgeState.autofillSetupProgress != .complete
        else { return false }
        return true
    }

    /// Whether the autofill off action card should be shown. Unlike the vault's card, this is
    /// shown whenever autofill is off, regardless of whether the user dismissed or opted out of
    /// the vault's card.
    var shouldShowAutofillOffActionCard: Bool {
        isAutofillOffActionCardEnabled && isAutofillEnabled == false
    }

    /// The warning message based on the default URI match type.
    var warningMessage: String? {
        switch defaultUriMatchType {
        case .regularExpression:
            Localizations.warningRegularExpressionIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials
        case .startsWith:
            Localizations.warningStartsWithIsAnAdvancedOptionWithIncreasedRiskOfExposingCredentials
        default:
            nil
        }
    }

    /// The options for URI match types ordered based on menu display.
    var uriMatchTypeOptions: [UriMatchType] {
        [
            UriMatchType.domain,
            UriMatchType.host,
            UriMatchType.exact,
            UriMatchType.never,
            UriMatchType.startsWith,
            UriMatchType.regularExpression,
        ]
    }
}
