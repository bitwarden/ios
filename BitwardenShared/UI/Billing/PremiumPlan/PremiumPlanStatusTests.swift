import BitwardenKit
import BitwardenResources
import Foundation
import Testing

@testable import BitwardenShared

// MARK: - PremiumPlanStatusTests

struct PremiumPlanStatusTests {
    // MARK: Tests - badgeStyle

    @Test(arguments: [
        (PremiumPlanStatus.active, PillBadgeStyle.success),
        (.canceled, .danger),
        (.expired, .danger),
        (.pastDue, .warning),
        (.pendingCancellation, .warning),
        (.unknown, .warning),
        (.unpaid, .danger),
        (.updatePayment, .warning),
    ] as [(PremiumPlanStatus, PillBadgeStyle)])
    func badgeStyle(_ status: PremiumPlanStatus, expected: PillBadgeStyle) {
        #expect(status.badgeStyle == expected)
    }

    // MARK: Tests - init

    @Test(arguments: [
        (SubscriptionStatus.active, PremiumPlanStatus.active),
        (.canceled, .canceled),
        (.incompleteExpired, .expired),
        (.pastDue, .pastDue),
        (.unknown, .unknown),
        (.unpaid, .unpaid),
    ] as [(SubscriptionStatus, PremiumPlanStatus)])
    func init_mapsSubscriptionStatus(_ status: SubscriptionStatus, expected: PremiumPlanStatus) {
        #expect(PremiumPlanStatus(subscriptionStatus: status) == expected)
    }

    @Test(arguments: [SubscriptionStatus.active, .trialing] as [SubscriptionStatus])
    func init_mapsSubscriptionStatus_withCancelAt(_ status: SubscriptionStatus) {
        let cancelAt = Date()
        #expect(PremiumPlanStatus(subscriptionStatus: status, cancelAt: cancelAt) == .pendingCancellation)
    }

    // MARK: Tests - isTroubleState

    @Test(arguments: [
        (PremiumPlanStatus.active, false),
        (.canceled, true),
        (.expired, true),
        (.pastDue, true),
        (.pendingCancellation, true),
        (.unknown, false),
        (.unpaid, true),
        (.updatePayment, true),
    ] as [(PremiumPlanStatus, Bool)])
    func isTroubleState(_ status: PremiumPlanStatus, expected: Bool) {
        #expect(status.isTroubleState == expected)
    }

    // MARK: Tests - isPaymentProblemState

    @Test(arguments: [
        (PremiumPlanStatus.active, false),
        (.canceled, false),
        (.expired, false),
        (.pastDue, true),
        (.pendingCancellation, false),
        (.unknown, false),
        (.unpaid, true),
        (.updatePayment, true),
    ] as [(PremiumPlanStatus, Bool)])
    func isPaymentProblemState(_ status: PremiumPlanStatus, expected: Bool) {
        #expect(status.isPaymentProblemState == expected)
    }

    // MARK: Tests - label

    @Test(arguments: [
        (PremiumPlanStatus.active, Localizations.active),
        (.canceled, Localizations.canceled),
        (.expired, Localizations.expired),
        (.pastDue, Localizations.pastDue),
        (.pendingCancellation, Localizations.pendingCancellation),
        (.unknown, Localizations.unknownStatus),
        (.unpaid, Localizations.unpaid),
        (.updatePayment, Localizations.updatePayment),
    ] as [(PremiumPlanStatus, String)])
    func label(_ status: PremiumPlanStatus, expected: String) {
        #expect(status.label == expected)
    }
}
