// MARK: - SelfHostedAction

/// Actions handled by the `SelfHostedProcessor`.
///
enum SelfHostedAction: Equatable {
    /// The API server URL has changed.
    case apiUrlChanged(String)

    /// The view was dismissed.
    case dismiss

    /// The icons server URL has changed.
    case iconsUrlChanged(String)

    /// The identity server URL has changed.
    case identityUrlChanged(String)

    /// The server URL has changed.
    case serverUrlChanged(String)

    /// The web vault server URL has changed.
    case webVaultUrlChanged(String)
}
