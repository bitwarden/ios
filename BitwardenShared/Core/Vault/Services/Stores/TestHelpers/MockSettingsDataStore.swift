@testable import BitwardenShared

class MockSettingsDataStore: SettingsDataStore {
    var deleteEquivalentDomainsCalled = false
    var deleteEquivalentDomainsUserId: String?
    var deleteEquivalentDomainsResult: Result<Void, Error> = .success(())

    var fetchDomainsResult: Result<DomainsResponseModel?, Error> = .success(nil)

    var replaceDomainsDomains: DomainsResponseModel?
    var replaceDomainsUserId: String?
    var replaceDomainsResult: Result<Void, Error> = .success(())

    func deleteEquivalentDomains(userId: String) async throws {
        deleteEquivalentDomainsCalled = true
        deleteEquivalentDomainsUserId = userId
        try deleteEquivalentDomainsResult.get()
    }

    func fetchEquivalentDomains(userId: String) async throws -> DomainsResponseModel? {
        try fetchDomainsResult.get()
    }

    func replaceEquivalentDomains(_ domains: DomainsResponseModel, userId: String) async throws {
        replaceDomainsDomains = domains
        replaceDomainsUserId = userId
        try replaceDomainsResult.get()
    }
}
