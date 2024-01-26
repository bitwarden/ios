// MARK: - PolicyService

/// A protocol for a `PolicyService` which manages syncing and updates to the user's policies.
///
protocol PolicyService: AnyObject {
    /// Determines whether a policy applies to the active user.
    ///
    /// - Parameter policyType: The policy to check.
    /// - Returns: Whether the policy applies to the user.
    ///
    func policyAppliesToUser(_ policyType: PolicyType) async -> Bool

    /// Replaces the list of policies for the user.
    ///
    /// - Parameters:
    ///   - domains: The list of policies.
    ///   - userId: The user ID associated with the policies.
    ///
    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws
}

// MARK: - DefaultPolicyService

/// A default implementation of a `PolicyService` which manages syncing and updates to the user's
/// policies.
///
class DefaultPolicyService: PolicyService {
    // MARK: Properties

    /// The data store for managing the persisted policies for the user.
    let policyDataStore: PolicyDataStore

    /// The service for managing the organizations for the user.
    let organizationService: OrganizationService

    /// The list of policies, keyed by the user's ID.
    private var policiesByUserId = [String: [Policy]]()

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultPolicyService`.
    ///
    /// - Parameters:
    ///   - policyDataStore: The data store for managing the persisted policies for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        organizationService: OrganizationService,
        policyDataStore: PolicyDataStore,
        stateService: StateService
    ) {
        self.organizationService = organizationService
        self.policyDataStore = policyDataStore
        self.stateService = stateService
    }

    // MARK: Private

    /// Determines whether an organization is exempt from a specific policy.
    ///
    /// - Parameters:
    ///   - organization: The organization used to determine if it is exempt.
    ///   - policyType: The policy to check.
    /// - Returns: Whether the organization is exempt from the policy.
    ///
    private func isOrganization(_ organization: Organization, exemptFrom policyType: PolicyType) -> Bool {
        if policyType == .maximumVaultTimeout {
            return organization.type == .owner
        }

        return organization.isExemptFromPolicies
    }

    /// Returns the list of policies that apply to the user.
    ///
    /// - Parameter userId: The user ID of the user.
    /// - Returns: The list of the user's policies.
    ///
    private func policiesForUser(userId: String) async throws -> [Policy] {
        if let policies = policiesByUserId[userId] {
            return policies
        }

        let policies = try await policyDataStore.fetchAllPolicies(userId: userId)
        policiesByUserId[userId] = policies
        return policies
    }
}

extension DefaultPolicyService {
    func policyAppliesToUser(_ policyType: PolicyType) async -> Bool {
        guard let userId = try? await stateService.getActiveAccountId(),
              let policies = try? await policiesForUser(userId: userId),
              let organizations = try? await organizationService.fetchAllOrganizations()
        else {
            return false
        }

        let filteredPolicies = policies.filter { $0.enabled && $0.type == policyType }

        // Determine the organizations that have this policy enabled.
        let organizationsWithPolicy = Set(filteredPolicies.map(\.organizationId))

        // The policy applies if one or more organizations that the user is in are are enabled, use
        // policies, have the policy enabled and the user is not exempt from policies.
        return organizations.contains { organization in
            organization.enabled &&
                (organization.status == .accepted || organization.status == .confirmed) &&
                organization.usePolicies &&
                !isOrganization(organization, exemptFrom: policyType) &&
                organizationsWithPolicy.contains(organization.id)
        }
    }

    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        policiesByUserId[userId] = policies.map(Policy.init)
        try await policyDataStore.replacePolicies(policies, userId: userId)
    }
}
