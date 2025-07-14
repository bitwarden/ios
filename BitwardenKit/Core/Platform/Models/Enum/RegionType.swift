// MARK: - RegionType

/// A region that the user can select when creating or signing into their account.
public enum RegionType: CaseIterable, Sendable {
    /// The United States region.
    case unitedStates

    /// The European region.
    case europe

    /// A self-hosted instance.
    case selfHosted

    /// The name for this region, localized.
    public var localizedName2: String {
        switch self {
        case .europe: return SpikeLocalizations.spikeBWK
        case .selfHosted: return SpikeLocalizations.spikeBWK
        case .unitedStates: return SpikeLocalizations.spikeBWK
        }
    }
}
