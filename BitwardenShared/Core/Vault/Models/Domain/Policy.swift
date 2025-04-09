import BitwardenKit

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

    /// The policy type.
    let type: PolicyType
}

extension Policy {
    init(responseModel: PolicyResponseModel) {
        self.init(
            data: responseModel.data,
            enabled: responseModel.enabled,
            id: responseModel.id,
            organizationId: responseModel.organizationId,
            type: responseModel.type
        )
    }

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
