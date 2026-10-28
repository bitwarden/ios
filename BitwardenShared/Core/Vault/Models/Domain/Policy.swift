import BitwardenKit
import Foundation

/// A domain model containing the details of a policy.
///
struct Policy: Equatable {
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

    /// The policy type.
    let type: PolicyType
}

extension Policy {
    /// Initialize a `Policy` from a `PolicyResponseModel`.
    ///
    /// - Parameter responseModel: The response model for the policy.
    /// - Returns: `nil` if the policy's type is missing or isn't recognized by this version of the
    ///   app.
    ///
    init?(responseModel: PolicyResponseModel) {
        guard let type = responseModel.type else { return nil }
        self.init(
            data: responseModel.data,
            enabled: responseModel.enabled,
            id: responseModel.id,
            organizationId: responseModel.organizationId,
            revisionDate: responseModel.revisionDate,
            type: type,
        )
    }

    /// Initialize a `Policy` from a persisted `PolicyData` object.
    ///
    /// - Parameter policyData: The persisted policy data.
    /// - Returns: `nil` if the policy's type isn't recognized by this version of the app.
    ///
    init?(policyData: PolicyData) throws {
        guard let model = policyData.model else {
            throw DataMappingError.invalidData
        }
        self.init(responseModel: model)
    }
}

extension Policy {
    /// A subscript to get a policy option type from the `data` dictionary.
    ///
    subscript(_ optionType: PolicyOptionType) -> AnyCodable? {
        data?[optionType.rawValue]
    }
}

extension [Policy] {
    /// The policy with the earliest revision date, or `nil` if the list is empty.
    ///
    var policyWithEarliestRevisionDate: Policy? {
        self.min { ($0.revisionDate ?? .distantFuture) < ($1.revisionDate ?? .distantFuture) }
    }
}
