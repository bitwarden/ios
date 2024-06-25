// MARK: - LandingEffect

/// Effects that can be processed by a `LandingProcessor`.
enum LandingEffect: Equatable {
    /// The vault list appeared on screen.
    case appeared

    /// The continue button was pressed.
    case continuePressed

    /// A Profile Switcher Effect.
    case profileSwitcher(ProfileSwitcherEffect)
}
