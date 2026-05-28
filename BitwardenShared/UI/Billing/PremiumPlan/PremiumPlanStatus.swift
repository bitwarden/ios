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

    /// The plan has expired due to an incomplete payment.
    case expired

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
        case .canceled,
             .expired:
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
        case .expired:
            Localizations.expired
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
             .paused:
            self = .canceled
        case .incompleteExpired:
            self = .expired
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
