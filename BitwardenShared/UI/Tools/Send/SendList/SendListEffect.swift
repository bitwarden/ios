// MARK: - SendListEffect

/// Effects that can be processed by a `SendListProcessor`.
enum SendListEffect {
    /// The send list appeared on screen.
    case appeared

    /// The send list is being refreshed.
    case refresh
}
