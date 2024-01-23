// MARK: - AppExtensionState

/// The state used to present the `AppExtensionView`.
struct AppExtensionState: Equatable {
    // MARK: Properties

    /// Whether the extension was activated.
    var extensionActivated = false

    /// Whether the extension is enabled.
    var extensionEnabled = false
}
