import Foundation

// MARK: - RegionType

/// A region that the user can select when creating or signing into their account.
public enum RegionType: CaseIterable, Sendable {
    /// The United States region.
    case unitedStates

    /// The European region.
    case europe

    /// The government cloud (FedRAMP) region.
    case gov

    /// A self-hosted instance.
    case selfHosted

    /// Bitwarden's internal/QA environment (any `bitwarden.pw` host). Not user-selectable.
    case `internal`
}

public extension RegionType {
    /// Determines the region for a given environment base URL. This is the single source of truth
    /// for mapping a base URL to a region; callers that hold an `EnvironmentURLData` or
    /// `EnvironmentURLs` should use their `region` property rather than reimplementing this.
    ///
    /// - Parameter baseURL: The environment's base URL (i.e. `EnvironmentURLData.base`).
    ///
    init(baseURL: URL?) {
        if baseURL == EnvironmentURLData.defaultUS.base {
            self = .unitedStates
        } else if baseURL == EnvironmentURLData.defaultEU.base {
            self = .europe
        } else if baseURL == EnvironmentURLData.defaultGov.base {
            self = .gov
        } else if let baseURL,
                  let host = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)?.host,
                  host == "bitwarden.pw" || host.hasSuffix(".bitwarden.pw") {
            self = .internal
        } else {
            self = .selfHosted
        }
    }
}
