import Foundation

/// A wrapper around non-optional URLs that the app uses in its environment.
///
public struct EnvironmentURLs: Equatable {
    // MARK: Properties

    /// The URL for the API.
    public let apiURL: URL

    /// The base URL.
    public let baseURL: URL

    /// The URL for changing email address.
    public let changeEmailURL: URL

    /// The URL for the events API.
    public let eventsURL: URL

    /// The URL for the icons API.
    public let iconsURL: URL

    /// The URL for the identity API.
    public let identityURL: URL

    /// The URL for importing items.
    public let importItemsURL: URL

    /// The URL for the recovery code help page.
    public let recoveryCodeURL: URL

    /// The URL for sharing a send.
    public let sendShareURL: URL

    /// The URL for vault settings.
    public let settingsURL: URL

    /// The URL for setting up two-factor login.
    public let setUpTwoFactorURL: URL

    /// The URL for upgrading to premium.
    public let upgradeToPremiumURL: URL

    /// The URL for the web vault.
    public let webVaultURL: URL

    /// Initializes an `Environment URLs`.
    ///
    /// - Parameters:
    ///   - apiURL: The URL for the API.
    ///   - baseURL: The base URL.
    ///   - changeEmailURL: The URL for changing email address.
    ///   - eventsURL: The URL for the events API.
    ///   - iconsURL: The URL for the icons API.
    ///   - identityURL: The URL for the identity API.
    ///   - importItemsURL: The URL for importing items.
    ///   - recoveryCodeURL: The URL for the recovery code help page.
    ///   - sendShareURL: The URL for sharing a send.
    ///   - settingsURL: The URL for vault settings.
    ///   - setUpTwoFactorURL: The URL for setting up two-factor login.
    ///   - upgradeToPremiumURL: The URL for upgrading to premium.
    ///   - webVaultURL: The URL for the web vault.
    public init(
        apiURL: URL,
        baseURL: URL,
        changeEmailURL: URL,
        eventsURL: URL,
        iconsURL: URL,
        identityURL: URL,
        importItemsURL: URL,
        recoveryCodeURL: URL,
        sendShareURL: URL,
        settingsURL: URL,
        setUpTwoFactorURL: URL,
        upgradeToPremiumURL: URL,
        webVaultURL: URL,
    ) {
        self.apiURL = apiURL
        self.baseURL = baseURL
        self.changeEmailURL = changeEmailURL
        self.eventsURL = eventsURL
        self.iconsURL = iconsURL
        self.identityURL = identityURL
        self.importItemsURL = importItemsURL
        self.recoveryCodeURL = recoveryCodeURL
        self.sendShareURL = sendShareURL
        self.settingsURL = settingsURL
        self.setUpTwoFactorURL = setUpTwoFactorURL
        self.upgradeToPremiumURL = upgradeToPremiumURL
        self.webVaultURL = webVaultURL
    }
}

public extension EnvironmentURLs {
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
            string: "https://vault.bitwarden.com/#/recover-2fa",
        )!
        sendShareURL = environmentURLData.sendShareURL ?? URL(string: "https://send.bitwarden.com/#")!
        settingsURL = environmentURLData.settingsURL ?? webVaultURL
        changeEmailURL = environmentURLData.changeEmailURL ?? settingsURL
        setUpTwoFactorURL = environmentURLData.setUpTwoFactorURL ?? settingsURL
        upgradeToPremiumURL = environmentURLData.upgradeToPremiumURL ?? settingsURL
    }
}
