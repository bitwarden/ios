import BitwardenResources

// MARK: - PlanCadenceType

/// The billing cadence for a subscription plan.
///
public enum PlanCadenceType: String, Codable, Equatable, Hashable, Sendable {
    /// An annual billing cadence.
    case annually

    /// A monthly billing cadence.
    case monthly

    /// The VoiceOver-friendly label for this cadence (e.g. "per month", "per year").
    var accessibilityLabel: String {
        switch self {
        case .annually:
            Localizations.perYearAccessibilityLabel
        case .monthly:
            Localizations.perMonthAccessibilityLabel
        }
    }

    /// The localized label for this cadence (e.g. "/ month", "/ year").
    var label: String {
        switch self {
        case .annually:
            Localizations.perYear
        case .monthly:
            Localizations.perMonth
        }
    }
}
