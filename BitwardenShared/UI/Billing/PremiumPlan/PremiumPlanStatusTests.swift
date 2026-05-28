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
        (.unpaid, .updatePayment),
    ] as [(SubscriptionStatus, PremiumPlanStatus)])
    func init_mapsSubscriptionStatus(_ status: SubscriptionStatus, expected: PremiumPlanStatus) {
        #expect(PremiumPlanStatus(subscriptionStatus: status) == expected)
    }

    @Test(arguments: [SubscriptionStatus.active, .trialing] as [SubscriptionStatus])
    func init_mapsSubscriptionStatus_withCancelAt(_ status: SubscriptionStatus) {
        let cancelAt = Date()
        #expect(PremiumPlanStatus(subscriptionStatus: status, cancelAt: cancelAt) == .pendingCancellation)
    }

    // MARK: Tests - label

    @Test(arguments: [
        (PremiumPlanStatus.active, Localizations.active),
        (.canceled, Localizations.canceled),
        (.expired, Localizations.expired),
        (.pastDue, Localizations.pastDue),
        (.pendingCancellation, Localizations.pendingCancellation),
        (.unknown, Localizations.unknownStatus),
        (.updatePayment, Localizations.updatePayment),
    ] as [(PremiumPlanStatus, String)])
    func label(_ status: PremiumPlanStatus, expected: String) {
        #expect(status.label == expected)
    }
}
