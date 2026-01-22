import Foundation

// MARK: - EnvironmentService

/// A protocol for an `EnvironmentService` which manages the app's environment URLs.
///
public protocol EnvironmentService {
    /// The URL for the API.
    var apiURL: URL { get }

    /// The environment's base URL.
    var baseURL: URL { get }

    /// The URL for changing email address.
    var changeEmailURL: URL { get }

    /// The URL for the events API.
    var eventsURL: URL { get }

    /// The URL for the icons API.
    var iconsURL: URL { get }

    /// The URL for the identity API.
    var identityURL: URL { get }

    /// The URL for importing items.
    var importItemsURL: URL { get }

    /// The URL for the recovery code help page.
    var recoveryCodeURL: URL { get }

    /// The region of the current environment.
    var region: RegionType { get }

    /// The URL for sharing a send.
    var sendShareURL: URL { get }

    /// The URL for vault settings.
    var settingsURL: URL { get }

    /// The URL for setting up two-factor login.
    var setUpTwoFactorURL: URL { get }

    /// The URL for upgrading to premium.
    var upgradeToPremiumURL: URL { get }

    /// The URL for the web vault.
    var webVaultURL: URL { get }

    /// Loads the URLs for the active account into the environment. This can be called on app launch
    /// whether there's an active account or not to pre-populate the environment. If there's no
    /// active account, the US URLs will be used.
    ///
    func loadURLsForActiveAccount() async

    /// Sets the pre-auth URLs for the environment. This should be called if there isn't an an
    /// active account on app launch or if the user navigates through the add/create account flow.
    ///
    /// - Parameter urls: The URLs to set and use prior to user authentication.
    ///
    func setPreAuthURLs(urls: EnvironmentURLData) async
}
