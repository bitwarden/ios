import Foundation

/// A wrapper around non-optional URLs that the app uses in its environment.
///
struct EnvironmentUrls: Equatable {
    // MARK: Properties

    /// The URL for the API.
    let apiURL: URL

    /// The base URL.
    let baseURL: URL

    /// The URL for the events API.
    let eventsURL: URL

    /// The URL for the icons API.
    let iconsURL: URL

    /// The URL for the identity API.
    let identityURL: URL

    /// The URL for importing items.
    let importItemsURL: URL

    /// The URL for the recovery code help page.
    let recoveryCodeURL: URL

    /// The URL for sharing a send.
    let sendShareURL: URL

    /// The URL for vault settings.
    let settingsURL: URL

    /// The URL for the web vault.
    let webVaultURL: URL
}

extension EnvironmentUrls {
    /// Initialize `EnvironmentUrls` from `EnvironmentUrlData`.
    ///
    /// - Parameter environmentUrlData: The environment URLs used to initialize `EnvironmentUrls`.
    ///
    init(environmentUrlData: EnvironmentUrlData) {
        if environmentUrlData.region == .selfHosted, let base = environmentUrlData.base {
            apiURL = base.appendingPathComponent("api")
            baseURL = base
            eventsURL = base.appendingPathComponent("events")
            iconsURL = base.appendingPathComponent("icons")
            identityURL = base.appendingPathComponent("identity")
            webVaultURL = base
        } else {
            apiURL = environmentUrlData.api ?? URL(string: "https://api.bitwarden.com")!
            baseURL = environmentUrlData.base ?? URL(string: "https://vault.bitwarden.com")!
            eventsURL = environmentUrlData.events ?? URL(string: "https://events.bitwarden.com")!
            iconsURL = environmentUrlData.icons ?? URL(string: "https://icons.bitwarden.net")!
            identityURL = environmentUrlData.identity ?? URL(string: "https://identity.bitwarden.com")!
            webVaultURL = environmentUrlData.webVault ?? URL(string: "https://vault.bitwarden.com")!
        }
        importItemsURL = environmentUrlData.importItemsURL ?? URL(string: "https://vault.bitwarden.com/#/tools/import")!
        recoveryCodeURL = environmentUrlData.recoveryCodeUrl ?? URL(
            string: "https://vault.bitwarden.com/#/recover-2fa"
        )!
        sendShareURL = environmentUrlData.sendShareURL ?? URL(string: "https://send.bitwarden.com/#")!
        settingsURL = environmentUrlData.settingsURL ?? webVaultURL
    }
}
