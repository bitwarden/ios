import Foundation

/// API response model for a policy.
///
struct PolicyResponseModel: Codable, Equatable {
    // MARK: Properties

    /// Whether the policy is enabled.
    let enabled: Bool

    /// The policy's identifier.
    let id: String?

    /// The response object type.
    let object: String?

    /// The organization identifier for the policy.
    let organizationId: String?

    /// The policy type.
    let type: PolicyType?
}
