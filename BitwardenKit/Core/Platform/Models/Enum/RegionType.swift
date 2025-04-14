// MARK: - RegionType

/// A region that the user can select when creating or signing into their account.
public enum RegionType: CaseIterable, Sendable {
    /// The United States region.
    case unitedStates

    /// The European region.
    case europe

    /// A self-hosted instance.
    case selfHosted
}
