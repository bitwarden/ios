import BitwardenResources

// MARK: - PlanCadenceType

/// The billing cadence for a subscription plan.
///
enum PlanCadenceType: String, Codable, Equatable, Sendable {
    /// An annual billing cadence.
    case annually

    /// A monthly billing cadence.
    case monthly

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
