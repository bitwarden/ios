// MARK: - VaultGroupEffect

/// Effects that can be handled by a `VaultGroupProcessor`.
enum VaultGroupEffect: Equatable {
    /// The vault group view appeared on screen.
    case appeared

    /// The refresh control was triggered.
    case refresh

    /// Stream the show web icons setting.
    case streamShowWebIcons
}
