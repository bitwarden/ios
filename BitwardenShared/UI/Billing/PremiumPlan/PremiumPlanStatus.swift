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

    /// The plan has an unknown status not yet supported by the app.
    case unknown

    /// The plan requires a payment method update.
    case updatePayment

    // MARK: Properties

    /// The pill badge style for this status.
    var badgeStyle: PillBadgeStyle {
        switch self {
        case .active:
            .success
        case .canceled:
            .danger
        case .pastDue,
             .unknown,
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
        case .unknown:
            Localizations.unknownStatus
        case .updatePayment:
            Localizations.updatePayment
        }
    }

    // MARK: Initialization

    /// Initializes a `PremiumPlanStatus` from a `SubscriptionStatus`.
    ///
    /// - Parameter subscriptionStatus: The subscription status from the API.
    ///
    init(subscriptionStatus: SubscriptionStatus) {
        switch subscriptionStatus {
        case .active,
             .trialing:
            self = .active
        case .canceled,
             .incompleteExpired,
             .paused:
            self = .canceled
        case .incomplete,
             .unpaid:
            self = .updatePayment
        case .pastDue:
            self = .pastDue
        case .unknown:
            self = .unknown
        }
    }
}
