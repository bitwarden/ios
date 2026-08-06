@testable import BitwardenShared

class MockPolicyDataStore: PolicyDataStore {
    var deleteAllPoliciesCalled = false
    var deleteAllPoliciesUserId: String?
    var deleteAllPoliciesResult: Result<Void, Error> = .success(())

    var deleteAllPoliciesNewCalled = false
    var deleteAllPoliciesNewUserId: String?
    var deleteAllPoliciesNewResult: Result<Void, Error> = .success(())

    var fetchPoliciesCount = 0
    var fetchPoliciesResult: Result<[Policy], Error> = .success([])

    var fetchPoliciesNewCount = 0
    var fetchPoliciesNewResult: Result<[Policy], Error> = .success([])

    var replacePoliciesPolicies = [PolicyResponseModel]()
    var replacePoliciesUserId: String?
    var replacePoliciesResult: Result<Void, Error> = .success(())

    var replacePoliciesNewPolicies = [PolicyResponseModel]()
    var replacePoliciesNewUserId: String?
    var replacePoliciesNewResult: Result<Void, Error> = .success(())

    func deleteAllPolicies(userId: String) async throws {
        deleteAllPoliciesCalled = true
        deleteAllPoliciesUserId = userId
        try deleteAllPoliciesResult.get()
    }

    func deleteAllPoliciesNew(userId: String) async throws {
        deleteAllPoliciesNewCalled = true
        deleteAllPoliciesNewUserId = userId
        try deleteAllPoliciesNewResult.get()
    }

    func fetchAllPolicies(userId: String) async throws -> [Policy] {
        fetchPoliciesCount += 1
        return try fetchPoliciesResult.get()
    }

    func fetchAllPoliciesNew(userId: String) async throws -> [Policy] {
        fetchPoliciesNewCount += 1
        return try fetchPoliciesNewResult.get()
    }

    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        replacePoliciesPolicies = policies
        replacePoliciesUserId = userId
        try replacePoliciesResult.get()
    }

    func replacePoliciesNew(_ policies: [PolicyResponseModel], userId: String) async throws {
        replacePoliciesNewPolicies = policies
        replacePoliciesNewUserId = userId
        try replacePoliciesNewResult.get()
    }
}
