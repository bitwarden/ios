import Foundation

@testable import BitwardenShared

class MockEnvironmentService: EnvironmentService {
    var didLoadURLsForActiveAccount = false
    var setActiveAccountEnvironmentUrlsData: EnvironmentUrlData?
    var setPreAuthEnvironmentUrlsData: EnvironmentUrlData?

    var apiURL = URL(string: "https://example.com/api")!
    var eventsURL = URL(string: "https://example.com/events")!
    var identityURL = URL(string: "https://example.com/identity")!

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
