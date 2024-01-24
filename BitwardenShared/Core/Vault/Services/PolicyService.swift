// MARK: - PolicyService

/// A protocol for a `PolicyService` which manages syncing and updates to the user's policies.
///
protocol PolicyService: AnyObject {
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

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultPolicyService`.
    ///
    /// - Parameters:
    ///   - policyDataStore: The data store for managing the persisted policies for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(policyDataStore: PolicyDataStore, stateService: StateService) {
        self.policyDataStore = policyDataStore
        self.stateService = stateService
    }
}

extension DefaultPolicyService {
    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        try await policyDataStore.replacePolicies(policies, userId: userId)
    }
}
