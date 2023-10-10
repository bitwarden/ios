import Foundation

/// Domain model containing the environment URLs for an account.
///
struct EnvironmentUrlData: Codable, Equatable {
    // MARK: Properties

    /// The URL for the API.
    let api: URL?

    /// The base URL.
    let base: URL?

    /// The URL for the events API.
    let events: URL?

    /// The URL for the identity API.
    let identity: URL?

    /// The URL for the icons API.
    let icons: URL?

    /// The URL for the notifications API.
    let notifications: URL?

    /// The URL for the web vault.
    let webVault: URL?
}
