import Foundation

@testable import BitwardenShared

class MockEnvironmentService: EnvironmentService {
    var didLoadURLsForActiveAccount = false
    var setActiveAccountEnvironmentUrlsData: EnvironmentUrlData?
    var setPreAuthEnvironmentUrlsData: EnvironmentUrlData?

    var apiURL = URL(string: "https://example.com/api")!
    var baseURL = URL(string: "https://example.com")!
    var changeEmailURL = URL(string: "https://example.com/#/settings/account")!
    var eventsURL = URL(string: "https://example.com/events")!
    var iconsURL = URL(string: "https://example.com/icons")!
    var identityURL = URL(string: "https://example.com/identity")!
    var importItemsURL = URL(string: "https://example.com/#/tools/import")!
    var recoveryCodeURL = URL(string: "https://example.com/#/recover-2fa")!
    var region = RegionType.selfHosted
    var sendShareURL = URL(string: "https://example.com/#/send")!
    var settingsURL = URL(string: "https://example.com/#/settings")!
    var setUpTwoFactorURL = URL(string: "https://example.com/#/settings/security/two-factor")!
    var webVaultURL = URL(string: "https://example.com")!

    func loadURLsForActiveAccount() async {
        didLoadURLsForActiveAccount = true
    }

    func setActiveAccountURLs(urls: EnvironmentUrlData) {
        setActiveAccountEnvironmentUrlsData = urls
    }

    func setPreAuthURLs(urls: EnvironmentUrlData) async {
        setPreAuthEnvironmentUrlsData = urls
    }
}
