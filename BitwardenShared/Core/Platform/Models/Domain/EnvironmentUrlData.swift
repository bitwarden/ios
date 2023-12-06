import Foundation

/// Domain model containing the environment URLs for an account.
///
struct EnvironmentUrlData: Codable, Equatable, Hashable {
    // MARK: Properties

    /// The URL for the API.
    let api: URL?

    /// The base URL.
    let base: URL?

    /// The URL for the events API.
    let events: URL?

    /// The URL for the icons API.
    let icons: URL?

    /// The URL for the identity API.
    let identity: URL?

    /// The URL for the notifications API.
    let notifications: URL?

    /// The URL for the web vault.
    let webVault: URL?

    // MARK: Initialization

    /// Initialize `EnvironmentUrlData` with the specified URLs.
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
    init(
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

extension EnvironmentUrlData {
    /// Whether all of the environment URLs are not set.
    var isEmpty: Bool {
        api == nil
            && base == nil
            && events == nil
            && icons == nil
            && identity == nil
            && notifications == nil
            && webVault == nil
    }

    /// The host of URL to the user's web vault.
    var webVaultHost: String? {
        let url = webVault ?? base
        return url?.host
    }
}

extension EnvironmentUrlData {
    /// The default URLs for the US region.
    static let defaultUS = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com")!)

    /// The default URLs for the EU region.
    static let defaultEU = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.eu")!)
}
