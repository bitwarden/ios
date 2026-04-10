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
        case .canceled, .pastDue:
            .danger
        case .updatePayment:
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

    /// The description text for the current plan status.
    var descriptionText: String = ""

    /// The billing amount label (e.g. "$1.65 / month").
    var billingAmount: String = ""

    /// The storage cost label (e.g. "$0.35").
    var storageCost: String = ""

    /// The discount label (e.g. "-$0.10").
    var discount: String = ""

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
