import BitwardenKit
import BitwardenResources
import Testing

@testable import BitwardenShared

// MARK: - PremiumPlanStatusTests

struct PremiumPlanStatusTests {
    // MARK: Tests - badgeStyle

    /// `badgeStyle` for `.active` returns `.success`.
    @Test
    func badgeStyle_active() {
        #expect(PremiumPlanStatus.active.badgeStyle == .success)
    }

    /// `badgeStyle` for `.canceled` returns `.danger`.
    @Test
    func badgeStyle_canceled() {
        #expect(PremiumPlanStatus.canceled.badgeStyle == .danger)
    }

    /// `badgeStyle` for `.pastDue` returns `.warning`.
    @Test
    func badgeStyle_pastDue() {
        #expect(PremiumPlanStatus.pastDue.badgeStyle == .warning)
    }

    /// `badgeStyle` for `.updatePayment` returns `.warning`.
    @Test
    func badgeStyle_updatePayment() {
        #expect(PremiumPlanStatus.updatePayment.badgeStyle == .warning)
    }

    // MARK: Tests - label

    /// `label` for `.active` returns the active localization.
    @Test
    func label_active() {
        #expect(PremiumPlanStatus.active.label == Localizations.active)
    }

    /// `label` for `.canceled` returns the canceled localization.
    @Test
    func label_canceled() {
        #expect(PremiumPlanStatus.canceled.label == Localizations.canceled)
    }

    /// `label` for `.pastDue` returns the past due localization.
    @Test
    func label_pastDue() {
        #expect(PremiumPlanStatus.pastDue.label == Localizations.pastDue)
    }

    /// `label` for `.updatePayment` returns the update payment localization.
    @Test
    func label_updatePayment() {
        #expect(PremiumPlanStatus.updatePayment.label == Localizations.updatePayment)
    }
}
