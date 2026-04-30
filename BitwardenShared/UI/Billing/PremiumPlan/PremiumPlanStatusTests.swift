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

    /// `badgeStyle` for `.unknown` returns `.warning`.
    @Test
    func badgeStyle_unknown() {
        #expect(PremiumPlanStatus.unknown.badgeStyle == .warning)
    }

    /// `badgeStyle` for `.updatePayment` returns `.warning`.
    @Test
    func badgeStyle_updatePayment() {
        #expect(PremiumPlanStatus.updatePayment.badgeStyle == .warning)
    }

    // MARK: Tests - init

    /// `init` maps `.active` to `.active`.
    @Test
    func init_active() {
        #expect(PremiumPlanStatus(.active) == .active)
    }

    /// `init` maps `.canceled` to `.canceled`.
    @Test
    func init_canceled() {
        #expect(PremiumPlanStatus(.canceled) == .canceled)
    }

    /// `init` maps `.pastDue` to `.pastDue`.
    @Test
    func init_pastDue() {
        #expect(PremiumPlanStatus(.pastDue) == .pastDue)
    }

    /// `init` maps `.unknown` to `.unknown`.
    @Test
    func init_unknown() {
        #expect(PremiumPlanStatus(.unknown) == .unknown)
    }

    /// `init` maps `.unpaid` to `.updatePayment`.
    @Test
    func init_unpaid() {
        #expect(PremiumPlanStatus(.unpaid) == .updatePayment)
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

    /// `label` for `.unknown` returns the unknown status localization.
    @Test
    func label_unknown() {
        #expect(PremiumPlanStatus.unknown.label == Localizations.unknownStatus)
    }

    /// `label` for `.updatePayment` returns the update payment localization.
    @Test
    func label_updatePayment() {
        #expect(PremiumPlanStatus.updatePayment.label == Localizations.updatePayment)
    }
}
