@testable import BitwardenShared

class MockPolicyDataStore: PolicyDataStore {
    var deleteAllPoliciesCalled = false
    var deleteAllPoliciesUserId: String?
    var deleteAllPoliciesResult: Result<Void, Error> = .success(())

    var fetchPoliciesResult: Result<[Policy], Error> = .success([])

    var replacePoliciesPolicies = [PolicyResponseModel]()
    var replacePoliciesUserId: String?
    var replacePoliciesResult: Result<Void, Error> = .success(())

    func deleteAllPolicies(userId: String) async throws {
        deleteAllPoliciesCalled = true
        deleteAllPoliciesUserId = userId
        try deleteAllPoliciesResult.get()
    }

    func fetchAllPolicies(userId: String) async throws -> [Policy] {
        try fetchPoliciesResult.get()
    }

    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        replacePoliciesPolicies = policies
        replacePoliciesUserId = userId
        try replacePoliciesResult.get()
    }
}
