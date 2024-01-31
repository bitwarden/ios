// MARK: - PolicyService

/// A protocol for a `PolicyService` which manages syncing and updates to the user's policies.
///
protocol PolicyService: AnyObject {
    /// Applies the password generation policy to the password generation options.
    ///
    /// - Parameter options: The options to apply the policy to.
    /// - Returns: Whether the password generation policy is in effect.
    ///
    func applyPasswordGenerationPolicy(options: inout PasswordGenerationOptions) async throws -> Bool

    /// Returns whether the send hide email option is disabled because of a policy.
    ///
    /// - Returns: Whether the send hide email option is disabled.
    ///
    func isSendHideEmailDisabledByPolicy() async -> Bool

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

    /// Determines whether a policy applies to the active user.
    ///
    /// - Parameters:
    ///   - policyType: The policy to check.
    ///   - filter: An optional filter to apply to the list of policies.
    /// - Returns: Whether the policy applies to the user.
    ///
    func policyAppliesToUser(_ policyType: PolicyType, filter: ((Policy) -> Bool)? = nil) async -> Bool {
        guard let userId = try? await stateService.getActiveAccountId(),
              let policies = try? await policiesForUser(userId: userId, type: policyType, filter: filter),
              let organizations = try? await organizationService.fetchAllOrganizations()
        else {
            return false
        }

        // Determine the organizations that have this policy enabled.
        let organizationsWithPolicy = Set(policies.map(\.organizationId))

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

    /// Returns the list of policies that apply to the user.
    ///
    /// - Parameters:
    ///   - userId: The user ID of the user.
    ///   - type: The type of policies to return.
    ///   - filter: An optional filter to apply to the list of policies.
    /// - Returns: The list of the user's policies.
    ///
    private func policiesForUser(
        userId: String,
        type: PolicyType,
        filter: ((Policy) -> Bool)? = nil
    ) async throws -> [Policy] {
        let policyFilter: (Policy) -> Bool = { policy in
            policy.enabled && policy.type == type && filter?(policy) ?? true
        }

        if let policies = policiesByUserId[userId] {
            return policies.filter(policyFilter)
        }

        let policies = try await policyDataStore.fetchAllPolicies(userId: userId)
        policiesByUserId[userId] = policies

        return policies.filter(policyFilter)
    }
}

extension DefaultPolicyService {
    // swiftlint:disable:next cyclomatic_complexity
    func applyPasswordGenerationPolicy(options: inout PasswordGenerationOptions) async throws -> Bool {
        guard let userId = try? await stateService.getActiveAccountId(),
              let policies = try? await policiesForUser(userId: userId, type: .passwordGenerator),
              !policies.isEmpty
        else {
            return false
        }

        // When determining the generator type, ignore the existing option's type to find the preferred
        // default type based on the policies. Then set it on `options` below.
        var generatorType: PasswordGeneratorType?
        for policy in policies {
            if let defaultTypeString = policy[.defaultType]?.stringValue,
               let defaultType = PasswordGeneratorType(rawValue: defaultTypeString),
               generatorType != .password {
                // If there's multiple policies with different default types, the password type
                // should take priority. Use `generateType` as opposed to `options.type` to ignore
                // the existing type in the options.
                generatorType = defaultType
            }

            if let minLength = policy[.minLength]?.intValue {
                options.setMinLength(minLength)
            }

            if policy[.useUpper]?.boolValue == true {
                options.uppercase = true
            }

            if policy[.useLower]?.boolValue == true {
                options.lowercase = true
            }

            if policy[.useNumbers]?.boolValue == true {
                options.number = true
            }

            if policy[.useSpecial]?.boolValue == true {
                options.special = true
            }

            if policy[.capitalize]?.boolValue == true {
                options.capitalize = true
            }

            if policy[.includeNumber]?.boolValue == true {
                options.includeNumber = true
            }

            if let minNumbers = policy[.minNumbers]?.intValue {
                options.setMinNumbers(minNumbers)
            }

            if let minSpecial = policy[.minSpecial]?.intValue {
                options.setMinSpecial(minSpecial)
            }

            if let minNumberWords = policy[.minNumberWords]?.intValue {
                options.setMinNumberWords(minNumberWords)
            }
        }

        // A type determine by the policy should take priority over the option's existing type.
        options.type = generatorType ?? options.type

        return true
    }

    func isSendHideEmailDisabledByPolicy() async -> Bool {
        await policyAppliesToUser(.sendOptions) { policy in
            policy[.disableHideEmail]?.boolValue == true
        }
    }

    func policyAppliesToUser(_ policyType: PolicyType) async -> Bool {
        await policyAppliesToUser(policyType, filter: nil)
    }

    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        policiesByUserId[userId] = policies.map(Policy.init)
        try await policyDataStore.replacePolicies(policies, userId: userId)
    }
}
