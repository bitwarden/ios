import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - PremiumPlanStatus

/// The status of the user's Premium plan.
///
public enum PremiumPlanStatus: Equatable, Hashable {
    /// The plan is active.
    case active

    /// The plan has been canceled.
    case canceled

    /// The plan has expired due to an incomplete payment.
    case expired

    /// The plan is past due.
    case pastDue

    /// The plan is active but scheduled to cancel at a future date.
    case pendingCancellation

    /// The plan has an unknown status not yet supported by the app.
    case unknown

    /// The subscription is unpaid after repeated payment failures; premium access has lapsed.
    case unpaid

    /// The plan requires a payment method update.
    case updatePayment

    // MARK: Properties

    /// The pill badge style for this status.
    var badgeStyle: PillBadgeStyle {
        switch self {
        case .active:
            .success
        case .canceled,
             .expired,
             .unpaid:
            .danger
        case .pastDue,
             .pendingCancellation,
             .unknown,
             .updatePayment:
            .warning
        }
    }

    /// Whether the status represents a subscription in a troubled state that affects billing UI —
    /// canceled, expired, past due, pending cancellation, unpaid, or update payment.
    ///
    /// This is broader than `isPaymentProblemState`: it covers every non-normal state, including
    /// those caused by user action (cancellation) or plan expiry, not only payment failures.
    var isTroubleState: Bool {
        switch self {
        case .canceled, .expired, .pastDue, .pendingCancellation, .unpaid, .updatePayment:
            true
        case .active, .unknown:
            false
        }
    }

    /// Whether the status represents a payment failure — past due, unpaid, or update payment.
    ///
    /// This is the narrower subset of `isTroubleState` that drives the "subscription needs
    /// attention" action card. It covers all three payment-problem states regardless of whether
    /// premium access is currently active: past due and update payment retain premium during
    /// the dunning grace period, while unpaid has already lapsed.
    var isPaymentProblemState: Bool {
        switch self {
        case .pastDue, .unpaid, .updatePayment:
            true
        case .active, .canceled, .expired, .pendingCancellation, .unknown:
            false
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
        case .pendingCancellation:
            Localizations.pendingCancellation
        case .unknown:
            Localizations.unknownStatus
        case .unpaid:
            Localizations.unpaid
        case .updatePayment:
            Localizations.updatePayment
        }
    }

    // MARK: Initialization

    /// Initializes a `PremiumPlanStatus` from a `SubscriptionStatus` and optional cancellation date.
    ///
    /// - Parameters:
    ///   - subscriptionStatus: The subscription status from the API.
    ///   - cancelAt: The scheduled cancellation date, if any.
    ///
    init(subscriptionStatus: SubscriptionStatus, cancelAt: Date? = nil) {
        switch subscriptionStatus {
        case .active,
             .trialing:
            self = cancelAt != nil ? .pendingCancellation : .active
        case .canceled,
             .paused:
            self = .canceled
        case .incompleteExpired:
            self = .expired
        case .incomplete:
            self = .updatePayment
        case .pastDue:
            self = .pastDue
        case .unknown:
            self = .unknown
        case .unpaid:
            self = .unpaid
        }
    }
}
