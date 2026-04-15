import BitwardenKit
import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - PremiumPlanStateTests

struct PremiumPlanStateTests {
    // MARK: Tests - descriptionText

    /// `descriptionText` returns the expected value for each plan status.
    @Test(arguments: [
        (
            PremiumPlanStatus.active,
            Localizations.yourNextChargeIsForXDueOnY(
                "$1.00 USD",
                "April 2, 2026",
            ),
        ),
        (
            PremiumPlanStatus.canceled,
            Localizations.yourSubscriptionWasCanceledOnXResubscribeToContinueUsingDescriptionLong(
                "April 2, 2026",
            ),
        ),
        (
            PremiumPlanStatus.pastDue,
            Localizations.youHaveAGracePeriodOfXFromYourSubscriptionDescriptionLong(
                "14 days",
                "Feb 2, 2026",
            ),
        ),
        (
            PremiumPlanStatus.updatePayment,
            Localizations.weCouldNotProcessYourPaymentUpdateYourPaymentMethodDescriptionLong(
                "May 2, 2026",
            ),
        ),
    ])
    func descriptionText(planStatus: PremiumPlanStatus, expected: String) {
        var state = PremiumPlanState()
        state.planStatus = planStatus
        #expect(state.descriptionText == expected)
    }

    // MARK: Tests - showBillingDetails

    /// `showBillingDetails` returns the expected value for each plan status.
    @Test(arguments: [
        (PremiumPlanStatus.active, true),
        (PremiumPlanStatus.canceled, false),
        (PremiumPlanStatus.pastDue, true),
        (PremiumPlanStatus.updatePayment, true),
    ])
    func showBillingDetails(planStatus: PremiumPlanStatus, expected: Bool) {
        var state = PremiumPlanState()
        state.planStatus = planStatus
        #expect(state.showBillingDetails == expected)
    }

    // MARK: Tests - showCancelButton

    /// `showCancelButton` returns the expected value for each plan status.
    @Test(arguments: [
        (PremiumPlanStatus.active, true),
        (PremiumPlanStatus.canceled, false),
        (PremiumPlanStatus.pastDue, true),
        (PremiumPlanStatus.updatePayment, true),
    ])
    func showCancelButton(planStatus: PremiumPlanStatus, expected: Bool) {
        var state = PremiumPlanState()
        state.planStatus = planStatus
        #expect(state.showCancelButton == expected)
    }
}
