/// Effects that can be performed by a `PremiumPlanProcessor`.
///
enum PremiumPlanEffect: Equatable {
    /// The view appeared.
    case appeared

    /// The manage plan button was tapped.
    case managePlanTapped

    /// The "Try again" button on the error view was tapped.
    case tryAgainTapped
}
