import Foundation

/// Domain model containing the environment URLs for an account.
///
public struct EnvironmentURLData: Codable, Equatable, Hashable, Sendable {
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
        webVault: URL? = nil,
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

public extension EnvironmentURLData {
    // MARK: Properties

    /// The URL for the user to change their email.
    var changeEmailURL: URL? {
        subpageURL(additionalPath: "settings/account")
    }

    /// The base url for importing items.
    var importItemsURL: URL? {
        subpageURL(additionalPath: "tools/import")
    }

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

    /// The URL for the recovery code help page.
    var recoveryCodeURL: URL? {
        subpageURL(additionalPath: "recover-2fa")
    }

    /// Gets the region depending on the base url.
    var region: RegionType {
        switch base {
        case EnvironmentURLData.defaultUS.base:
            .unitedStates
        case EnvironmentURLData.defaultEU.base:
            .europe
        default:
            .selfHosted
        }
    }

    /// The base url for send sharing.
    var sendShareURL: URL? {
        guard region != .unitedStates else {
            return URL(string: "https://send.bitwarden.com/#")!
        }
        return subpageURL(additionalPath: "send")
    }

    /// The base url for the settings screen.
    var settingsURL: URL? {
        subpageURL(additionalPath: "settings")
    }

    /// The URL to set up two-factor login.
    var setUpTwoFactorURL: URL? {
        subpageURL(additionalPath: "settings/security/two-factor")
    }

    /// The host of URL to the user's web vault.
    var webVaultHost: String? {
        let url = webVault ?? base
        return url?.host
    }

    // MARK: Methods

    /// The URL for a given subpage of the vault webpage.
    ///
    /// - Parameters:
    ///   - additionalPath: The additional path string to append to the vault's base URL
    private func subpageURL(additionalPath: String) -> URL? {
        // Foundation's URL appending methods percent encode the path component that is passed into the method,
        // which includes the `#` symbol. Since the `#` character is a critical portion of these urls, we use String
        // concatenation to get around this limitation.
        if let baseURL = webVault ?? base,
           let url = URL(string: baseURL.sanitized.absoluteString.appending("/#/\(additionalPath)")) {
            return url
        }
        return nil
    }
}

public extension EnvironmentURLData {
    /// The default URLs for the US region.
    static let defaultUS = EnvironmentURLData(
        api: URL(string: "https://api.bitwarden.com")!,
        base: URL(string: "https://vault.bitwarden.com")!,
        events: URL(string: "https://events.bitwarden.com")!,
        icons: URL(string: "https://icons.bitwarden.net")!,
        identity: URL(string: "https://identity.bitwarden.com")!,
        notifications: URL(string: "https://notifications.bitwarden.com")!,
        webVault: URL(string: "https://vault.bitwarden.com")!,
    )

    /// The default URLs for the EU region.
    static let defaultEU = EnvironmentURLData(
        api: URL(string: "https://api.bitwarden.eu")!,
        base: URL(string: "https://vault.bitwarden.eu")!,
        events: URL(string: "https://events.bitwarden.eu")!,
        icons: URL(string: "https://icons.bitwarden.eu")!,
        identity: URL(string: "https://identity.bitwarden.eu")!,
        notifications: URL(string: "https://notifications.bitwarden.eu")!,
        webVault: URL(string: "https://vault.bitwarden.eu")!,
    )
}
