import Foundation

/// Domain model containing the environment URLs for an account.
///
public struct EnvironmentURLData: Codable, Equatable, Hashable {
    // MARK: Properties

    /// The URL for the API.
    public let api: URL?

    /// The base URL.
    public let base: URL?

    /// The URL for the events API.
    public let events: URL?

    /// The URL for the icons API.
    public let icons: URL?

    /// The URL for the identity API.
    public let identity: URL?

    /// The URL for the notifications API.
    public let notifications: URL?

    /// The URL for the web vault.
    public let webVault: URL?

    // MARK: Initialization

    /// Initialize `EnvironmentURLData` with the specified URLs.
    ///
    /// - Parameters:
    ///   - api: The URL for the API.
    ///   - base: The base URL.
    ///   - events: The URL for the events API.
    ///   - icons: The URL for the icons API.
    ///   - identity: The URL for the identity API.
    ///   - notifications: The URL for the notifications API.
    ///   - webVault: The URL for the web vault.
    ///
    public init(
        api: URL? = nil,
        base: URL? = nil,
        events: URL? = nil,
        icons: URL? = nil,
        identity: URL? = nil,
        notifications: URL? = nil,
        webVault: URL? = nil
    ) {
        self.api = api
        self.base = base
        self.events = events
        self.icons = icons
        self.identity = identity
        self.notifications = notifications
        self.webVault = webVault
    }
}
