/// Actions that can be processed by a `PremiumPlanProcessor`.
///
enum PremiumPlanAction: Equatable {
    /// The manage plan button was pressed.
    case managePlanPressed

    /// The cancel premium button was pressed.
    case cancelPremiumPressed

    /// The manage plan URL has been opened and should be cleared.
    case clearManagePlanUrl

    /// The cancel premium URL has been opened and should be cleared.
    case clearCancelPremiumUrl
}
