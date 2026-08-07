import BitwardenKit
import BitwardenSdk
@testable import BitwardenShared

class MockPolicyService: PolicyService {
    var applyPasswordGenerationOptionsCalled = false
    var applyPasswordGenerationOptionsError: Error?
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

    var getSendPolicyOptionsResult = SendPolicyOptions()

    var fetchTimeoutPolicyValuesResult: Result<SessionTimeoutPolicy?, Error> = .success(nil)

    var getEarliestOrganizationApplyingPolicyResult: [BitwardenShared.PolicyType: String?] = [:] // swiftlint:disable:this identifier_name line_length

    // swiftlint:disable:next identifier_name
    var getOrganizationUserNotificationBannerDataResult: OrganizationUserNotificationBannerData?

    var organizationsApplyingPolicyToUserResult: [BitwardenShared.PolicyType: [String]] = [:]

    var policyAppliesToUserResult = [BitwardenShared.PolicyType: Bool]()
    var policyAppliesToUserPoliciesType = [BitwardenShared.PolicyType]()
    var policyAppliesToUserPolicies = [Policy]()
    var getRestrictedItemCipherTypesResult: [BitwardenShared.CipherType] = []

    var replacePoliciesPolicies = [PolicyResponseModel]()
    var replacePoliciesUserId: String?
    var replacePoliciesResult: Result<Void, Error> = .success(())

    var replacePoliciesNewPolicies = [PolicyResponseModel]()
    var replacePoliciesNewUserId: String?
    var replacePoliciesNewResult: Result<Void, Error> = .success(())

    func applyPasswordGenerationPolicy(options: inout PasswordGenerationOptions) async throws -> Bool {
        applyPasswordGenerationOptionsCalled = true
        if let applyPasswordGenerationOptionsError {
            throw applyPasswordGenerationOptionsError
        }
        applyPasswordGenerationOptionsTransform(&options)
        return applyPasswordGenerationOptionsResult
    }

    func getOrganizationIdsForRestricItemTypesPolicy() async -> [String] {
        policyAppliesToUserPolicies.map(\.organizationId)
    }

    func getOrganizationUserNotificationBannerData() async -> OrganizationUserNotificationBannerData? {
        getOrganizationUserNotificationBannerDataResult
    }

    func getRestrictedItemCipherTypes() async -> [BitwardenShared.CipherType] {
        getRestrictedItemCipherTypesResult
    }

    func getMasterPasswordPolicyOptions() async throws -> MasterPasswordPolicyOptions? {
        try getMasterPasswordPolicyOptionsResult.get()
    }

    func getSendPolicyOptions() async -> SendPolicyOptions {
        getSendPolicyOptionsResult
    }

    func fetchTimeoutPolicyValues() async throws -> SessionTimeoutPolicy? {
        try fetchTimeoutPolicyValuesResult.get()
    }

    func getEarliestOrganizationApplyingPolicy(_ policyType: BitwardenShared.PolicyType) async -> String? {
        getEarliestOrganizationApplyingPolicyResult[policyType] ?? nil
    }

    func organizationsApplyingPolicyToUser(_ policyType: BitwardenShared.PolicyType) async -> [String] {
        organizationsApplyingPolicyToUserResult[policyType] ?? []
    }

    func policyAppliesToUser(_ policyType: BitwardenShared.PolicyType) async -> Bool {
        policyAppliesToUserPoliciesType.append(policyType)
        return policyAppliesToUserResult[policyType] ?? false
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
