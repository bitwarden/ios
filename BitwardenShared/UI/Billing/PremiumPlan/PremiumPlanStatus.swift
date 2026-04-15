import BitwardenKit
import BitwardenResources

// MARK: - PremiumPlanStatus

/// The status of the user's premium plan.
///
enum PremiumPlanStatus: Equatable {
    /// The plan is active.
    case active

    /// The plan has been canceled.
    case canceled

    /// The plan is past due.
    case pastDue

    /// The plan requires a payment method update.
    case updatePayment

    /// The pill badge style for this status.
    var badgeStyle: PillBadgeStyle {
        switch self {
        case .active:
            .success
        case .canceled:
            .danger
        case .pastDue,
             .updatePayment:
            .warning
        }
    }

    /// The localized label for this status.
    var label: String {
        switch self {
        case .active:
            Localizations.active
        case .canceled:
            Localizations.canceled
        case .pastDue:
            Localizations.pastDue
        case .updatePayment:
            Localizations.updatePayment
        }
    }
}
