import Foundation

@testable import BitwardenKit

public class MockEnvironmentService: EnvironmentService {
    public var didLoadURLsForActiveAccount = false
    public var setActiveAccountEnvironmentURLsData: EnvironmentURLData?
    public var setPreAuthEnvironmentURLsData: EnvironmentURLData?

    public var apiURL = URL(string: "https://example.com/api")!
    public var baseURL = URL(string: "https://example.com")!
    public var changeEmailURL = URL(string: "https://example.com/#/settings/account")!
    public var eventsURL = URL(string: "https://example.com/events")!
    public var iconsURL = URL(string: "https://example.com/icons")!
    public var identityURL = URL(string: "https://example.com/identity")!
    public var importItemsURL = URL(string: "https://example.com/#/tools/import")!
    public var recoveryCodeURL = URL(string: "https://example.com/#/recover-2fa")!
    public var region = RegionType.selfHosted
    public var sendShareURL = URL(string: "https://example.com/#/send")!
    public var settingsURL = URL(string: "https://example.com/#/settings")!
    public var setUpTwoFactorURL = URL(string: "https://example.com/#/settings/security/two-factor")!
    public var upgradeToPremiumURL = URL(
        string: "https://example.com/#/settings/subscription/premium?callToAction=upgradeToPremium",
    )!
    public var webVaultURL = URL(string: "https://example.com")!

    public init() {}

    public func loadURLsForActiveAccount() async {
        didLoadURLsForActiveAccount = true
    }

    public func setActiveAccountURLs(urls: EnvironmentURLData) {
        setActiveAccountEnvironmentURLsData = urls
    }

    public func setPreAuthURLs(urls: EnvironmentURLData) async {
        setPreAuthEnvironmentURLsData = urls
    }
}
