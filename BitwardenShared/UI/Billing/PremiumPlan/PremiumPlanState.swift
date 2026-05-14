import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - PremiumPlanState

/// An object that defines the current state of a `PremiumPlanView`.
///
struct PremiumPlanState: Equatable {
    // MARK: Properties

    /// The current status of the premium plan.
    var planStatus: PremiumPlanStatus = .active

    /// The subscription details.
    var subscription: PremiumSubscription?

    /// The URL to open externally (manage plan or cancel premium).
    var urlToOpen: URL?

    // MARK: Computed Properties

    /// The billing amount label (e.g. "$19.80 / year").
    var billingAmount: String {
        guard let subscription else { return "" }
        return Localizations.xAmountPerCadence(
            formatCurrency(subscription.seatsCost),
            subscription.cadence.label,
        )
    }

    /// The date the subscription was canceled, formatted for display.
    var canceledDate: String {
        guard let canceled = subscription?.canceled else { return "" }
        return formatDate(canceled)
    }

    /// The description text for the current plan status.
    var descriptionText: String {
        switch planStatus {
        case .active:
            Localizations.yourNextChargeIsForXDueOnY(
                nextChargeAmount,
                nextChargeDate,
            )
        case .canceled:
            Localizations.yourSubscriptionWasCanceledOnXResubscribeToContinueUsingDescriptionLong(
                canceledDate,
            )
        case .pastDue:
            Localizations.youHaveAGracePeriodOfXDaysFromYourSubscriptionDescriptionLong(
                subscription?.gracePeriod ?? 0,
                subscriptionEndDate,
            )
        case .unknown:
            Localizations.yourSubscriptionStatusIsUnknownVisitTheWebAppDescriptionLong
        case .updatePayment:
            Localizations.weCouldNotProcessYourPaymentUpdateYourPaymentMethodDescriptionLong(
                subscriptionEndDate,
            )
        }
    }

    /// The discount label (e.g. "-$0.10").
    var discount: String {
        guard let subscription, subscription.discount > 0 else { return "" }
        return Localizations.negativeX(formatCurrency(subscription.discount))
    }

    /// The estimated tax label (e.g. "$4.55").
    var estimatedTax: String {
        guard let subscription, subscription.estimatedTax > 0 else { return "" }
        return formatCurrency(subscription.estimatedTax)
    }

    /// The next charge amount with currency code, formatted for display (e.g. "24.35 USD").
    var nextChargeAmount: String {
        guard let subscription, subscription.nextCharge != nil else { return "" }
        return formatCurrencyCode(subscription.totalAmount)
    }

    /// The next charge date, formatted for display.
    var nextChargeDate: String {
        guard let nextCharge = subscription?.nextCharge else { return "" }
        return formatDate(nextCharge)
    }

    /// Whether the billing details section should be shown.
    var showBillingDetails: Bool {
        planStatus != .canceled && planStatus != .unknown
    }

    /// Whether the cancel premium button should be shown.
    var showCancelButton: Bool {
        planStatus != .canceled && planStatus != .unknown
    }

    /// Whether the discount row should be shown.
    var showDiscount: Bool {
        !discount.isEmpty
    }

    /// Whether the estimated tax row should be shown.
    var showEstimatedTax: Bool {
        !estimatedTax.isEmpty
    }

    /// Whether the storage cost row should be shown.
    var showStorageCost: Bool {
        (subscription?.storageCost ?? 0) > 0
    }

    /// The storage cost label (e.g. "$4.00").
    var storageCostLabel: String {
        guard let subscription, subscription.storageCost > 0 else { return "" }
        return formatCurrency(subscription.storageCost)
    }

    /// The date the subscription ends or will be suspended, formatted for display.
    var subscriptionEndDate: String {
        if let suspension = subscription?.suspension {
            return formatDate(suspension)
        } else if let cancelAt = subscription?.cancelAt {
            return formatDate(cancelAt)
        }
        return ""
    }

    // MARK: Private Methods

    /// Formats a decimal price as a US dollar currency string using the currency symbol.
    ///
    /// - Parameter price: The price to format.
    /// - Returns: A formatted currency string (e.g. "$1.65").
    ///
    private func formatCurrency(_ price: Decimal) -> String {
        NumberFormatter.usdCurrency.string(from: price as NSDecimalNumber) ?? "--"
    }

    /// Formats a decimal price as a US dollar currency string using the ISO currency code.
    ///
    /// - Parameter price: The price to format.
    /// - Returns: A formatted currency string (e.g. "1.65 USD").
    ///
    private func formatCurrencyCode(_ price: Decimal) -> String {
        NumberFormatter.usdCurrencyCode.string(from: price as NSDecimalNumber) ?? "--"
    }

    /// Formats a date for display using the long date style (e.g. "April 2, 2026").
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A formatted date string.
    ///
    private func formatDate(_ date: Date) -> String {
        date.formatted(date: .long, time: .omitted)
    }
}
