import BitwardenKit
import BitwardenSdk
@testable import BitwardenShared

class MockPolicyService: PolicyService {
    var applyPasswordGenerationOptionsCalled = false
    var applyPasswordGenerationOptionsResult = false
    var applyPasswordGenerationOptionsTransform = { (_: inout PasswordGenerationOptions) in }

    var getMasterPasswordPolicyOptionsResult: Result<MasterPasswordPolicyOptions?, Error> = .success(
        MasterPasswordPolicyOptions(
            minComplexity: 2,
            minLength: 8,
            requireUpper: true,
            requireLower: false,
            requireNumbers: true,
            requireSpecial: false,
            enforceOnLogin: true,
        ),
    )

    var isSendHideEmailDisabledByPolicy = false

    var fetchTimeoutPolicyValuesResult: Result<SessionTimeoutPolicy?, Error> = .success(nil)

    var getEarliestOrganizationApplyingPolicyResult: [PolicyType: String?] = [:]

    var organizationsApplyingPolicyToUserResult: [PolicyType: [String]] = [:]

    var policyAppliesToUserResult = [PolicyType: Bool]()
    var policyAppliesToUserPoliciesType = [PolicyType]()
    var policyAppliesToUserPolicies = [Policy]()
    var getRestrictedItemCipherTypesResult: [BitwardenShared.CipherType] = []

    var replacePoliciesPolicies = [PolicyResponseModel]()
    var replacePoliciesUserId: String?
    var replacePoliciesResult: Result<Void, Error> = .success(())

    func applyPasswordGenerationPolicy(options: inout PasswordGenerationOptions) async throws -> Bool {
        applyPasswordGenerationOptionsCalled = true
        applyPasswordGenerationOptionsTransform(&options)
        return applyPasswordGenerationOptionsResult
    }

    func getOrganizationIdsForRestricItemTypesPolicy() async -> [String] {
        policyAppliesToUserPolicies.map(\.organizationId)
    }

    func getRestrictedItemCipherTypes() async -> [BitwardenShared.CipherType] {
        getRestrictedItemCipherTypesResult
    }

    func getMasterPasswordPolicyOptions() async throws -> MasterPasswordPolicyOptions? {
        try getMasterPasswordPolicyOptionsResult.get()
    }

    func isSendHideEmailDisabledByPolicy() async -> Bool {
        isSendHideEmailDisabledByPolicy
    }

    func fetchTimeoutPolicyValues() async throws -> SessionTimeoutPolicy? {
        try fetchTimeoutPolicyValuesResult.get()
    }

    func getEarliestOrganizationApplyingPolicy(_ policyType: PolicyType) async -> String? {
        getEarliestOrganizationApplyingPolicyResult[policyType] ?? nil
    }

    func organizationsApplyingPolicyToUser(_ policyType: BitwardenShared.PolicyType) async -> [String] {
        organizationsApplyingPolicyToUserResult[policyType] ?? []
    }

    func policyAppliesToUser(_ policyType: PolicyType) async -> Bool {
        policyAppliesToUserPoliciesType.append(policyType)
        return policyAppliesToUserResult[policyType] ?? false
    }

    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        replacePoliciesPolicies = policies
        replacePoliciesUserId = userId
        try replacePoliciesResult.get()
    }
}
