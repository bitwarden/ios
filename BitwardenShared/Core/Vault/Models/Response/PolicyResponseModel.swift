import Foundation

/// API response model for a policy.
///
struct PolicyResponseModel: Codable, Equatable {
    // MARK: Properties

    /// Custom policy key value pairs.
    let data: [String: AnyCodable]?

    /// Whether the policy is enabled.
    let enabled: Bool

    /// The policy's identifier.
    let id: String

    /// The organization identifier for the policy.
    let organizationId: String

    /// The policy type.
    let type: PolicyType
}
