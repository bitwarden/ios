/// Effects that can be processed by an `GeneratorProcessor`.
///
enum GeneratorEffect {
    /// The generator view appeared on screen.
    case appeared

    /// The user tapped the dismiss button on the learn generator action card.
    case dismissLearnGeneratorActionCard

    /// Show the learn generator guided tour.
    case showLearnGeneratorGuidedTour
}
