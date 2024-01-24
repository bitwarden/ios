@testable import BitwardenShared

class MockSettingsDataStore: SettingsDataStore {
    var deleteEquivalentDomainsCalled = false
    var deleteEquivalentDomainsUserId: String?
    var deleteEquivalentDomainsResult: Result<Void, Error> = .success(())

    var deleteAllPoliciesCalled = false
    var deleteAllPoliciesUserId: String?
    var deleteAllPoliciesResult: Result<Void, Error> = .success(())

    var fetchDomainsResult: Result<DomainsResponseModel?, Error> = .success(nil)

    var fetchPoliciesResult: Result<[Policy], Error> = .success([])

    var replaceDomainsDomains: DomainsResponseModel?
    var replaceDomainsUserId: String?
    var replaceDomainsResult: Result<Void, Error> = .success(())

    var replacePoliciesPolicies = [PolicyResponseModel]()
    var replacePoliciesUserId: String?
    var replacePoliciesResult: Result<Void, Error> = .success(())

    func deleteEquivalentDomains(userId: String) async throws {
        deleteEquivalentDomainsCalled = true
        deleteEquivalentDomainsUserId = userId
        try deleteEquivalentDomainsResult.get()
    }

    func deleteAllPolicies(userId: String) async throws {
        deleteAllPoliciesCalled = true
        deleteAllPoliciesUserId = userId
        try deleteAllPoliciesResult.get()
    }

    func fetchAllPolicies(userId: String) async throws -> [Policy] {
        try fetchPoliciesResult.get()
    }

    func fetchEquivalentDomains(userId: String) async throws -> DomainsResponseModel? {
        try fetchDomainsResult.get()
    }

    func replaceEquivalentDomains(_ domains: DomainsResponseModel, userId: String) async throws {
        replaceDomainsDomains = domains
        replaceDomainsUserId = userId
        try replaceDomainsResult.get()
    }

    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        replacePoliciesPolicies = policies
        replacePoliciesUserId = userId
        try replacePoliciesResult.get()
    }
}
