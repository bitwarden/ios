/// Actions that can be processed by a `PremiumPlanProcessor`.
///
enum PremiumPlanAction: Equatable {
    /// The cancel Premium button was tapped.
    case cancelPremiumTapped

    /// The URL has been opened and should be cleared.
    case clearUrl
}
