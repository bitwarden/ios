import BitwardenKit
@preconcurrency import BitwardenSdk

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

    /// If the policy for a maximum vault timeout value is enabled,
    /// return the value and action to take upon timeout.
    ///
    /// - Returns: The timeout value in minutes, and the action to take upon timeout.
    ///
    func fetchTimeoutPolicyValues() async throws -> (action: SessionTimeoutAction?, value: Int)?

    /// Go through current users policy, filter them and build a master password policy options based on enabled policy.
    /// - Returns: Optional `MasterPasswordPolicyOptions` if it exist.
    ///
    func getMasterPasswordPolicyOptions() async throws -> MasterPasswordPolicyOptions?

    /// Get all active restricted item types policy organization ids that apply to the active user.
    ///
    /// - Returns: Active policy organization ids that apply to the user.
    ///
    func getOrganizationIdsForRestricItemTypesPolicy() async -> [String]

    /// Get the restricted types based on the organization's policies.
    ///
    /// - Returns: An array of restricted `CipherType`s.
    ///
    func getRestrictedItemCipherTypes() async -> [CipherType]

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
actor DefaultPolicyService: PolicyService {
    // MARK: Properties

    /// The service to get server-specified configuration.
    let configService: ConfigService

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
    ///   - configService: The service to get server-specified configuration.
    ///   - organizationService: The service for managing the organizations for the user.
    ///   - policyDataStore: The data store for managing the persisted policies for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        configService: ConfigService,
        organizationService: OrganizationService,
        policyDataStore: PolicyDataStore,
        stateService: StateService
    ) {
        self.configService = configService
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
        if policyType == .passwordGenerator
            || policyType == .removeUnlockWithPin
            || policyType == .restrictItemTypes {
            return false
        }

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
    private func policyAppliesToUser(_ policyType: PolicyType, filter: ((Policy) -> Bool)? = nil) async -> Bool {
        await !policiesApplyingToUser(policyType, filter: filter).isEmpty
    }

    /// The list of policies for a policy type that apply to the active user.
    ///
    /// - Parameters:
    ///   - policyType: The policy to check.
    ///   - filter: An optional filter to apply to the list of policies.
    /// - Returns: The list of policies that apply to the user.
    ///
    private func policiesApplyingToUser(_ policyType: PolicyType, filter: ((Policy) -> Bool)? = nil) async -> [Policy] {
        guard let userId = try? await stateService.getActiveAccountId(),
              let policies = try? await policiesForUser(userId: userId, type: policyType, filter: filter),
              let organizations = try? await organizationService.fetchAllOrganizations()
        else {
            return []
        }

        // The policy applies even if the organization is disabled, uses policies, has the policy enabled,
        // and the user is not exempt from policies.
        return policies.filter { policy in
            guard let organization = organizations.first(where: { $0.id == policy.organizationId })
            else { return false }
            return (organization.status == .accepted || organization.status == .confirmed) &&
                organization.usePolicies &&
                !isOrganization(organization, exemptFrom: policyType)
        }
    }

    /// Returns the list of policies that are assigned to the user.
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
        let policies: [Policy]
        if let cachedPolicies = policiesByUserId[userId] {
            policies = cachedPolicies
        } else {
            policies = try await policyDataStore.fetchAllPolicies(userId: userId)
            policiesByUserId[userId] = policies
        }

        return policies.filter { policy in
            policy.enabled && policy.type == type && filter?(policy) ?? true
        }
    }
}

extension DefaultPolicyService {
    // swiftlint:disable:next cyclomatic_complexity
    func applyPasswordGenerationPolicy(options: inout PasswordGenerationOptions) async throws -> Bool {
        let policies = await policiesApplyingToUser(.passwordGenerator)
        guard !policies.isEmpty else { return false }

        // When determining the generator type, ignore the existing option's type to find the preferred
        // default type based on the policies. Then set it on `options` below.
        var generatorType: PasswordGeneratorType?
        options.overridePasswordType = false
        for policy in policies {
            if let overridePasswordTypeString = policy[.overridePasswordType]?.stringValue,
               let overridePasswordType = PasswordGeneratorType(rawValue: overridePasswordTypeString),
               generatorType != .password {
                // If there's multiple policies with different default types, the password type
                // should take priority. Use `generateType` as opposed to `options.type` to ignore
                // the existing type in the options.
                generatorType = overridePasswordType
                options.overridePasswordType = true
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

    func fetchTimeoutPolicyValues() async throws -> (action: SessionTimeoutAction?, value: Int)? {
        let policies = await policiesApplyingToUser(.maximumVaultTimeout)
        guard !policies.isEmpty else { return nil }

        var timeoutAction: SessionTimeoutAction?
        var timeoutValue = 0

        for policy in policies {
            guard let policyTimeoutValue = policy[.minutes]?.intValue else { continue }
            timeoutValue = policyTimeoutValue

            // If the policy's timeout action is not lock or logOut, there is no policy timeout action.
            // In that case, we would present both timeout action options to the user.
            guard let action = policy[.action]?.stringValue, action == "lock" || action == "logOut" else {
                return (nil, timeoutValue)
            }
            timeoutAction = action == "lock" ? .lock : .logout
        }
        return (timeoutAction, timeoutValue)
    }

    func getMasterPasswordPolicyOptions() async throws -> MasterPasswordPolicyOptions? {
        let policies = await policiesApplyingToUser(.masterPassword) { $0.data != nil }
        guard !policies.isEmpty else { return nil }

        var minComplexity: UInt8 = 0
        var minLength: UInt8 = 0
        var requireUpper = false
        var requireLower = false
        var requireNumbers = false
        var requireSpecial = false
        var enforceOnLogin = false

        for policy in policies {
            if let minimumComplexity = policy[.minComplexity]?.intValue,
               minimumComplexity > minComplexity,
               let uint8Value = UInt8(exactly: minimumComplexity) {
                minComplexity = uint8Value
            }

            if let minimumLength = policy[.minLength]?.intValue,
               minimumLength > minLength,
               let uint8Value = UInt8(exactly: minimumLength) {
                minLength = uint8Value
            }

            if policy[.requireUpper]?.boolValue == true {
                requireUpper = true
            }

            if policy[.requireLower]?.boolValue == true {
                requireLower = true
            }

            if policy[.requireNumbers]?.boolValue == true {
                requireNumbers = true
            }

            if policy[.requireSpecial]?.boolValue == true {
                requireSpecial = true
            }

            if policy[.enforceOnLogin]?.boolValue == true {
                enforceOnLogin = true
            }
        }

        return MasterPasswordPolicyOptions(
            minComplexity: minComplexity,
            minLength: minLength,
            requireUpper: requireUpper,
            requireLower: requireLower,
            requireNumbers: requireNumbers,
            requireSpecial: requireSpecial,
            enforceOnLogin: enforceOnLogin
        )
    }

    func getOrganizationIdsForRestricItemTypesPolicy() async -> [String] {
        await policiesApplyingToUser(.restrictItemTypes, filter: nil).map { policy in
            policy.organizationId
        }
    }

    func getRestrictedItemCipherTypes() async -> [CipherType] {
        let restrictedTypesOrgIds = await getOrganizationIdsForRestricItemTypesPolicy()
        guard !restrictedTypesOrgIds.isEmpty else {
            return []
        }

        return [.card]
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
