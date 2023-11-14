// MARK: - SelfHostedState

/// An object that defines the current state of a `SelfHostedView`.
///
struct SelfHostedState: Equatable {
    /// The API server URL.
    var apiServerUrl: String = ""

    /// The icons server URL.
    var iconsServerUrl: String = ""

    /// The identity server URL.
    var identityServerUrl: String = ""

    /// The server URL.
    var serverUrl: String = ""

    /// The web vault server URL.
    var webVaultServerUrl: String = ""
}
