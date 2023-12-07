// MARK: - LandingEffect

/// Effects that can be processed by a `LandingProcessor`.
enum LandingEffect {
    /// The vault list appeared on screen.
    case appeared

    /// A Profile Switcher Effect.
    case profileSwitcher(ProfileSwitcherEffect)
}
