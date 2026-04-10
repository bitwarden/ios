import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - PremiumPlanStatus

/// The status of the user's premium plan.
///
enum PremiumPlanStatus: Equatable {
    /// The plan is active.
    case active

    /// The plan has been canceled.
    case canceled

    /// The plan requires a payment method update.
    case updatePayment

    /// The plan is past due.
    case pastDue

    /// The pill badge style for this status.
    var badgeStyle: PillBadgeStyle {
        switch self {
        case .active:
            .success
        case .canceled:
            .danger
        case .pastDue, .updatePayment:
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

// MARK: - PremiumPlanState

/// An object that defines the current state of a `PremiumPlanView`.
///
struct PremiumPlanState: Equatable {
    // MARK: Properties

    /// The current status of the premium plan.
    var planStatus: PremiumPlanStatus = .active

    // TODO: PM-34904 Replace mock values with real data from the API.
    /// The description text for the current plan status.
    var descriptionText: String {
        switch planStatus {
        case .active:
            Localizations.yourNextChargeIsForAmountDueOnDate(
                "$1.00 USD",
                "April 2, 2026",
            )
        case .canceled:
            Localizations.yourSubscriptionWasCanceledOnDateResubscribeToContinueUsingPremiumFeatures(
                "April 2, 2026",
            )
        case .updatePayment:
            Localizations
                .weCouldntProcessYourPaymentUpdateYourPaymentMethodBeforeSubscriptionEndsOnDate(
                    "May 2, 2026",
                )
        case .pastDue:
            Localizations
                .youHaveAGracePeriodOfDaysFromYourSubscriptionExpirationDateResolveInvoicesByDate(
                    "14 days",
                    "Feb 2, 2026",
                )
        }
    }

    // TODO: PM-34904 Replace mock values with real data from the API.
    /// The billing amount label (e.g. "$1.65 / month").
    var billingAmount: String = "$1.65 / month"

    // TODO: PM-34904 Replace mock values with real data from the API.
    /// The storage cost label (e.g. "$0.35").
    var storageCost: String = "$0.35"

    // TODO: PM-34904 Replace mock values with real data from the API.
    /// The discount label (e.g. "-$0.10").
    var discount: String = "-$0.10"

    /// The URL to open for managing the plan.
    var managePlanUrl: URL?

    /// The URL to open for canceling the plan.
    var cancelPremiumUrl: URL?

    // MARK: Computed Properties

    /// Whether the billing details section should be shown.
    var showBillingDetails: Bool {
        planStatus != .canceled
    }

    /// Whether the cancel premium button should be shown.
    var showCancelButton: Bool {
        planStatus != .canceled
    }
}
