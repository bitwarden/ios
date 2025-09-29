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

    /// Whether or not the copy TOTP automatically toggle is on.
    var isCopyTOTPToggleOn: Bool = false

    /// The url to open in the device's web browser.
    var url: URL?

    // MARK: Computed Properties

    /// Whether the autofill action card should be shown.
    var shouldShowAutofillActionCard: Bool {
        guard let badgeState, badgeState.autofillSetupProgress != .complete else { return false }
        return true
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
