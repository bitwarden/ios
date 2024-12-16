import Foundation

/// A wrapper around non-optional URLs that the app uses in its environment.
///
struct EnvironmentURLs: Equatable {
    // MARK: Properties

    /// The URL for the API.
    let apiURL: URL

    /// The base URL.
    let baseURL: URL

    /// The URL for changing email address.
    let changeEmailURL: URL

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

    /// The URL for setting up two-factor login.
    let setUpTwoFactorURL: URL

    /// The URL for the web vault.
    let webVaultURL: URL
}

extension EnvironmentURLs {
    /// Initialize `EnvironmentURLs` from `EnvironmentURLData`.
    ///
    /// - Parameter environmentURLData: The environment URLs used to initialize `EnvironmentURLs`.
    ///
    init(environmentURLData: EnvironmentURLData) {
        // Use the default URLs if the region matches US or EU.
        let environmentURLData: EnvironmentURLData = switch environmentURLData.region {
        case .europe: .defaultEU
        case .unitedStates: .defaultUS
        case .selfHosted: environmentURLData
        }

        if environmentURLData.region == .selfHosted, let base = environmentURLData.base {
            apiURL = base.appendingPathComponent("api")
            baseURL = base
            eventsURL = base.appendingPathComponent("events")
            iconsURL = base.appendingPathComponent("icons")
            identityURL = base.appendingPathComponent("identity")
            webVaultURL = base
        } else {
            apiURL = environmentURLData.api ?? URL(string: "https://api.bitwarden.com")!
            baseURL = environmentURLData.base ?? URL(string: "https://vault.bitwarden.com")!
            eventsURL = environmentURLData.events ?? URL(string: "https://events.bitwarden.com")!
            iconsURL = environmentURLData.icons ?? URL(string: "https://icons.bitwarden.net")!
            identityURL = environmentURLData.identity ?? URL(string: "https://identity.bitwarden.com")!
            webVaultURL = environmentURLData.webVault ?? URL(string: "https://vault.bitwarden.com")!
        }
        importItemsURL = environmentURLData.importItemsURL ?? URL(string: "https://vault.bitwarden.com/#/tools/import")!
        recoveryCodeURL = environmentURLData.recoveryCodeURL ?? URL(
            string: "https://vault.bitwarden.com/#/recover-2fa"
        )!
        sendShareURL = environmentURLData.sendShareURL ?? URL(string: "https://send.bitwarden.com/#")!
        settingsURL = environmentURLData.settingsURL ?? webVaultURL
        changeEmailURL = environmentURLData.changeEmailURL ?? settingsURL
        setUpTwoFactorURL = environmentURLData.setUpTwoFactorURL ?? settingsURL
    }
}
