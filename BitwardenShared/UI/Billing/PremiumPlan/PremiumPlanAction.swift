/// Actions that can be processed by a `PremiumPlanProcessor`.
///
enum PremiumPlanAction: Equatable {
    /// The cancel premium button was pressed.
    case cancelPremiumPressed

    /// The URL has been opened and should be cleared.
    case clearUrl

    /// The manage plan button was pressed.
    case managePlanPressed
}
