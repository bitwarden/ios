import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - PremiumPlanState

/// An object that defines the current state of a `PremiumPlanView`.
///
struct PremiumPlanState: Equatable {
    // MARK: Properties

    /// The billing amount label (e.g. "$1.65 / month").
    var billingAmount: String = ""

    /// The discount label (e.g. "-$0.10").
    var discount: String = "-$0.10"

    /// The current status of the premium plan.
    var planStatus: PremiumPlanStatus = .active

    /// The storage cost label (e.g. "$0.35").
    var storageCost: String = ""

    /// The URL to open externally (manage plan or cancel premium).
    var urlToOpen: URL?

    // MARK: Computed Properties

    // TODO: PM-35100 Replace mock values with real data from the API.
    /// The description text for the current plan status.
    var descriptionText: String {
        switch planStatus {
        case .active:
            Localizations.yourNextChargeIsForXDueOnY(
                "$1.00 USD",
                "April 2, 2026",
            )
        case .canceled:
            Localizations.yourSubscriptionWasCanceledOnXResubscribeToContinueUsingDescriptionLong(
                "April 2, 2026",
            )
        case .pastDue:
            Localizations.youHaveAGracePeriodOfXFromYourSubscriptionDescriptionLong(
                "14 days",
                "Feb 2, 2026",
            )
        case .updatePayment:
            Localizations.weCouldNotProcessYourPaymentUpdateYourPaymentMethodDescriptionLong(
                "May 2, 2026",
            )
        }
    }

    /// Whether the billing details section should be shown.
    var showBillingDetails: Bool {
        planStatus != .canceled
    }

    /// Whether the cancel premium button should be shown.
    var showCancelButton: Bool {
        planStatus != .canceled
    }
}
