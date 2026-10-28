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

    /// The policy type, or `nil` if it's missing or isn't recognized by this version of the app.
    /// Decoded via `OpenEnum` so that an unrecognized policy type doesn't fail decoding of the sync
    /// response, and round-trips when persisted. Use `$type` to access the original raw value.
    @OpenEnumValue var type: PolicyType?
}
