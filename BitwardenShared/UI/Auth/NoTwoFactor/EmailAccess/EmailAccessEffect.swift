// MARK: - EmailAccessEffect

/// Effects that can be processed by a `EmailAccessProcessor`.
///
enum EmailAccessEffect: Equatable, Sendable {
    /// The new device notice appeared on screen.
    case appeared
}
