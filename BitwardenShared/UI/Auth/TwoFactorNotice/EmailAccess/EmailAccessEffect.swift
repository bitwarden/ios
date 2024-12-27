// MARK: - EmailAccessEffect

/// Effects that can be processed by a `EmailAccessProcessor`.
///
enum EmailAccessEffect: Equatable, Sendable {
    /// The user tapped the continue button.
    case continueTapped
}
