@testable import BitwardenShared

class MockSettingsService: SettingsService {
    var fetchEquivalentDomainsResult: Result<[[String]], Error> = .success([[]])

    var replaceEquivalentDomainsDomains: DomainsResponseModel?
    var replaceEquivalentDomainsUserId: String?
    var replaceEquivalentDomainsResult: Result<Void, Error> = .success(())

    func fetchEquivalentDomains() async throws -> [[String]] {
        try fetchEquivalentDomainsResult.get()
    }

    func replaceEquivalentDomains(_ domains: DomainsResponseModel?, userId: String) async throws {
        replaceEquivalentDomainsDomains = domains
        replaceEquivalentDomainsUserId = userId
        try replaceEquivalentDomainsResult.get()
    }
}
