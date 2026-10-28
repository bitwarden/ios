import BitwardenKit
import Foundation

/// API response model for a policy.
///
struct PolicyResponseModel: Codable, Equatable, Sendable {
    // MARK: Properties

    /// Custom policy key value pairs.
    let data: [String: AnyCodable]?

    /// Whether the policy is enabled.
    let enabled: Bool

    /// The policy's identifier.
    let id: String

    /// The organization identifier for the policy.
    let organizationId: String

    /// The date the policy was last revised.
    let revisionDate: Date?

    /// The policy type. Wrapped in `OpenEnum` so that a policy type this version of the app doesn't
    /// recognize doesn't fail decoding of the sync response, and round-trips when persisted.
    let type: OpenEnum<PolicyType>
}
