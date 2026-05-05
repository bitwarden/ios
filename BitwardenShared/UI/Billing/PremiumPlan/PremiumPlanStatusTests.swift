import BitwardenKit
import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - PremiumPlanStatusTests

struct PremiumPlanStatusTests {
    // MARK: Tests - badgeStyle

    @Test(arguments: [
        (PremiumPlanStatus.active, PillBadgeStyle.success),
        (.canceled, .danger),
        (.pastDue, .warning),
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
        (.pastDue, .pastDue),
        (.unknown, .unknown),
        (.unpaid, .updatePayment),
    ] as [(SubscriptionStatus, PremiumPlanStatus)])
    func init_mapsSubscriptionStatus(_ status: SubscriptionStatus, expected: PremiumPlanStatus) {
        #expect(PremiumPlanStatus(subscriptionStatus: status) == expected)
    }

    // MARK: Tests - label

    @Test(arguments: [
        (PremiumPlanStatus.active, Localizations.active),
        (.canceled, Localizations.canceled),
        (.pastDue, Localizations.pastDue),
        (.unknown, Localizations.unknownStatus),
        (.updatePayment, Localizations.updatePayment),
    ] as [(PremiumPlanStatus, String)])
    func label(_ status: PremiumPlanStatus, expected: String) {
        #expect(status.label == expected)
    }
}
