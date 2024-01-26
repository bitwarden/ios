@testable import BitwardenShared

class MockPolicyService: PolicyService {
    var policyAppliesToUserResult = [PolicyType: Bool]()
    var policyAppliesToUserPolicies = [PolicyType]()

    var replacePoliciesPolicies = [PolicyResponseModel]()
    var replacePoliciesUserId: String?
    var replacePoliciesResult: Result<Void, Error> = .success(())

    func policyAppliesToUser(_ policyType: PolicyType) async -> Bool {
        policyAppliesToUserPolicies.append(policyType)
        return policyAppliesToUserResult[policyType] ?? false
    }

    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        replacePoliciesPolicies = policies
        replacePoliciesUserId = userId
        try replacePoliciesResult.get()
    }
}
