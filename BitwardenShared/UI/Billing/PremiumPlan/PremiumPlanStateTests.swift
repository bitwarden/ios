import BitwardenKit
import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - PremiumPlanStateTests

struct PremiumPlanStateTests {
    // MARK: Tests - descriptionText

    /// `descriptionText` for `.active` returns the next charge description.
    @Test
    func descriptionText_active() {
        var state = PremiumPlanState()
        state.planStatus = .active
        #expect(state.descriptionText == Localizations.yourNextChargeIsForXDueOnY(
            "$1.00 USD",
            "April 2, 2026",
        ))
    }

    /// `descriptionText` for `.canceled` returns the canceled description.
    @Test
    func descriptionText_canceled() {
        var state = PremiumPlanState()
        state.planStatus = .canceled
        #expect(state.descriptionText == Localizations.yourSubscriptionWasCanceledOnXResubscribeToContinueUsingDescriptionLong(
                "April 2, 2026",
            ))
    }

    /// `descriptionText` for `.pastDue` returns the past due description.
    @Test
    func descriptionText_pastDue() {
        var state = PremiumPlanState()
        state.planStatus = .pastDue
        #expect(state.descriptionText == Localizations.youHaveAGracePeriodOfXFromYourSubscriptionDescriptionLong(
            "14 days",
            "Feb 2, 2026",
        ))
    }

    /// `descriptionText` for `.updatePayment` returns the update payment description.
    @Test
    func descriptionText_updatePayment() {
        var state = PremiumPlanState()
        state.planStatus = .updatePayment
        #expect(state.descriptionText == Localizations.weCouldNotProcessYourPaymentUpdateYourPaymentMethodDescriptionLong(
            "May 2, 2026",
        ))
    }

    // MARK: Tests - showBillingDetails

    /// `showBillingDetails` returns `true` when status is `.active`.
    @Test
    func showBillingDetails_active() {
        var state = PremiumPlanState()
        state.planStatus = .active
        #expect(state.showBillingDetails)
    }

    /// `showBillingDetails` returns `false` when status is `.canceled`.
    @Test
    func showBillingDetails_canceled() {
        var state = PremiumPlanState()
        state.planStatus = .canceled
        #expect(!state.showBillingDetails)
    }

    /// `showBillingDetails` returns `true` when status is `.pastDue`.
    @Test
    func showBillingDetails_pastDue() {
        var state = PremiumPlanState()
        state.planStatus = .pastDue
        #expect(state.showBillingDetails)
    }

    /// `showBillingDetails` returns `true` when status is `.updatePayment`.
    @Test
    func showBillingDetails_updatePayment() {
        var state = PremiumPlanState()
        state.planStatus = .updatePayment
        #expect(state.showBillingDetails)
    }

    // MARK: Tests - showCancelButton

    /// `showCancelButton` returns `true` when status is `.active`.
    @Test
    func showCancelButton_active() {
        var state = PremiumPlanState()
        state.planStatus = .active
        #expect(state.showCancelButton)
    }

    /// `showCancelButton` returns `false` when status is `.canceled`.
    @Test
    func showCancelButton_canceled() {
        var state = PremiumPlanState()
        state.planStatus = .canceled
        #expect(!state.showCancelButton)
    }

    /// `showCancelButton` returns `true` when status is `.pastDue`.
    @Test
    func showCancelButton_pastDue() {
        var state = PremiumPlanState()
        state.planStatus = .pastDue
        #expect(state.showCancelButton)
    }

    /// `showCancelButton` returns `true` when status is `.updatePayment`.
    @Test
    func showCancelButton_updatePayment() {
        var state = PremiumPlanState()
        state.planStatus = .updatePayment
        #expect(state.showCancelButton)
    }
}
