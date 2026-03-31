/// An enum representing the product tier type.
///
public enum ProductTierType: Int, Codable, Equatable, Sendable {
    /// Free tier.
    case free = 0

    /// Families tier.
    case families = 1

    /// Teams tier.
    case teams = 2

    /// Enterprise tier.
    case enterprise = 3

    /// Teams Starter tier.
    case teamsStarter = 4
}

public extension ProductTierType {
    /// Returns whether the product tier is not self-upgradable.
    ///
    /// - Returns: `true` if the product tier cannot be upgraded by the user themselves.
    ///
    var isNotSelfUpgradable: Bool {
        self != .free && self != .teamsStarter && self != .families
    }
}
