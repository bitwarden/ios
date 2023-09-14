import Foundation

/// API response model for a policy.
///
struct PolicyResponseModel: Codable, Equatable {
    // MARK: Properties

    // TODO: BIT-309 Parse `data` field.

    /// Whether the policy is enabled.
    let enabled: Bool

    /// The policy's identifier.
    let id: String

    /// The organization identifier for the policy.
    let organizationId: String

    /// The policy type.
    let type: PolicyType
}
