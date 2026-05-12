import BitwardenKit
import BitwardenResources
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - PremiumPlanStateTests

struct PremiumPlanStateTests {
    // MARK: Properties

    /// A date used for testing: April 2, 2026 at 12:00 UTC.
    private let testDate = Date(timeIntervalSince1970: 1_775_304_000)

    // MARK: Tests - billingAmount

    /// `billingAmount` returns the formatted seat cost with cadence label.
    @Test
    func billingAmount() {
        var state = PremiumPlanState()
        state.subscription = .fixture(seatsCost: 19.8)
        #expect(state.billingAmount.contains("$19.80"))
        #expect(state.billingAmount.contains(Localizations.perYear))
    }

    /// `billingAmount` returns empty when subscription is nil.
    @Test
    func billingAmount_nil() {
        let state = PremiumPlanState()
        #expect(state.billingAmount.isEmpty)
    }

    // MARK: Tests - descriptionText

    /// `descriptionText` returns the correct text for the active plan status.
    @Test
    func descriptionText_active() {
        var state = PremiumPlanState()
        state.planStatus = .active
        state.subscription = .fixture(
            estimatedTax: 4.55,
            nextCharge: testDate,
        )
        let expectedAmount = state.nextChargeAmount
        let expectedDate = state.nextChargeDate
        #expect(state.descriptionText == Localizations.yourNextChargeIsForXDueOnY(
            expectedAmount,
            expectedDate,
        ))
    }

    /// `descriptionText` returns the correct text for the canceled plan status.
    @Test
    func descriptionText_canceled() {
        var state = PremiumPlanState()
        state.planStatus = .canceled
        state.subscription = .fixture(canceled: testDate, status: .canceled)
        #expect(state.descriptionText == Localizations
            .yourSubscriptionWasCanceledOnXResubscribeToContinueUsingDescriptionLong(
                state.canceledDate,
            ))
    }

    /// `descriptionText` returns the correct text for the past due plan status.
    @Test
    func descriptionText_pastDue() {
        var state = PremiumPlanState()
        state.planStatus = .pastDue
        state.subscription = .fixture(
            gracePeriod: 14,
            status: .pastDue,
            suspension: testDate,
        )
        #expect(state.descriptionText == Localizations
            .youHaveAGracePeriodOfXDaysFromYourSubscriptionDescriptionLong(
                state.subscription?.gracePeriod ?? 0,
                state.subscriptionEndDate,
            ))
    }

    /// `descriptionText` returns the correct text for the update payment plan status.
    @Test
    func descriptionText_updatePayment() {
        var state = PremiumPlanState()
        state.planStatus = .updatePayment
        state.subscription = .fixture(cancelAt: testDate, status: .updatePayment)
        #expect(state.descriptionText == Localizations
            .weCouldNotProcessYourPaymentUpdateYourPaymentMethodDescriptionLong(
                state.subscriptionEndDate,
            ))
    }

    // MARK: Tests - discount

    /// `discount` returns the formatted discount when discount is greater than zero.
    @Test
    func discount_withDiscount() {
        var state = PremiumPlanState()
        state.subscription = .fixture(discount: 2)
        #expect(state.discount == Localizations.negativeX("$2.00"))
    }

    /// `discount` returns empty when discount is zero.
    @Test
    func discount_noDiscount() {
        var state = PremiumPlanState()
        state.subscription = .fixture(discount: 0)
        #expect(state.discount.isEmpty)
    }

    // MARK: Tests - estimatedTax

    /// `estimatedTax` returns the formatted tax when tax is greater than zero.
    @Test
    func estimatedTax_withTax() {
        var state = PremiumPlanState()
        state.subscription = .fixture(estimatedTax: 4.55)
        #expect(state.estimatedTax == "$4.55")
    }

    /// `estimatedTax` returns empty when tax is zero.
    @Test
    func estimatedTax_zero() {
        var state = PremiumPlanState()
        state.subscription = .fixture(estimatedTax: 0)
        #expect(state.estimatedTax.isEmpty)
    }

    // MARK: Tests - showBillingDetails

    /// `showBillingDetails` returns the expected value for each plan status.
    @Test(arguments: [
        (PremiumPlanStatus.active, true),
        (PremiumPlanStatus.canceled, false),
        (PremiumPlanStatus.pastDue, true),
        (PremiumPlanStatus.unknown, false),
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
        (PremiumPlanStatus.unknown, false),
        (PremiumPlanStatus.updatePayment, true),
    ])
    func showCancelButton(planStatus: PremiumPlanStatus, expected: Bool) {
        var state = PremiumPlanState()
        state.planStatus = planStatus
        #expect(state.showCancelButton == expected)
    }

    // MARK: Tests - showDiscount

    /// `showDiscount` is true when there is a discount.
    @Test
    func showDiscount_true() {
        var state = PremiumPlanState()
        state.subscription = .fixture(discount: 5)
        #expect(state.showDiscount)
    }

    /// `showDiscount` is false when there is no discount.
    @Test
    func showDiscount_false() {
        var state = PremiumPlanState()
        state.subscription = .fixture(discount: 0)
        #expect(!state.showDiscount)
    }

    // MARK: Tests - showEstimatedTax

    /// `showEstimatedTax` is true when estimated tax is greater than zero.
    @Test
    func showEstimatedTax_true() {
        var state = PremiumPlanState()
        state.subscription = .fixture(estimatedTax: 4.55)
        #expect(state.showEstimatedTax)
    }

    /// `showEstimatedTax` is false when estimated tax is zero.
    @Test
    func showEstimatedTax_false() {
        var state = PremiumPlanState()
        state.subscription = .fixture(estimatedTax: 0)
        #expect(!state.showEstimatedTax)
    }

    // MARK: Tests - showStorageCost

    /// `showStorageCost` is true when storage cost is greater than zero.
    @Test
    func showStorageCost_true() {
        var state = PremiumPlanState()
        state.subscription = .fixture(storageCost: 4)
        #expect(state.showStorageCost)
    }

    /// `showStorageCost` is false when storage cost is zero.
    @Test
    func showStorageCost_false() {
        var state = PremiumPlanState()
        state.subscription = .fixture(storageCost: 0)
        #expect(!state.showStorageCost)
    }

    // MARK: Tests - storageCostLabel

    /// `storageCostLabel` returns the formatted storage cost.
    @Test
    func storageCostLabel_withStorage() {
        var state = PremiumPlanState()
        state.subscription = .fixture(storageCost: 8)
        #expect(state.storageCostLabel == "$8.00")
    }

    /// `storageCostLabel` returns empty when storage cost is zero.
    @Test
    func storageCostLabel_noStorage() {
        var state = PremiumPlanState()
        state.subscription = .fixture(storageCost: 0)
        #expect(state.storageCostLabel.isEmpty)
    }

    // MARK: Tests - subscriptionEndDate

    /// `subscriptionEndDate` returns the suspension date when available.
    @Test
    func subscriptionEndDate_suspension() {
        var state = PremiumPlanState()
        state.subscription = .fixture(suspension: testDate)
        #expect(!state.subscriptionEndDate.isEmpty)
    }

    /// `subscriptionEndDate` returns the cancelAt date when suspension is nil.
    @Test
    func subscriptionEndDate_cancelAt() {
        var state = PremiumPlanState()
        state.subscription = .fixture(cancelAt: testDate)
        #expect(!state.subscriptionEndDate.isEmpty)
    }

    /// `subscriptionEndDate` returns empty when neither date is set.
    @Test
    func subscriptionEndDate_empty() {
        var state = PremiumPlanState()
        state.subscription = .fixture()
        #expect(state.subscriptionEndDate.isEmpty)
    }
}
