import Foundation

/// A wrapper around non-optional URLs that the app uses in its environment.
///
struct EnvironmentUrls: Equatable {
    // MARK: Properties

    /// The URL for the API.
    let apiURL: URL

    /// The base URL.
    let baseURL: URL

    /// The URL for the events API.
    let eventsURL: URL

    /// The URL for the identity API.
    let identityURL: URL
}

extension EnvironmentUrls {
    /// Initialize `EnvironmentUrls` from `EnvironmentUrlData`.
    ///
    /// - Parameter environmentUrlData: The environment URLs used to initialize `EnvironmentUrls`.
    ///
    init(environmentUrlData: EnvironmentUrlData) {
        if let base = environmentUrlData.base {
            apiURL = base.appendingPathComponent("/api")
            baseURL = base
            eventsURL = base.appendingPathComponent("/events")
            identityURL = base.appendingPathComponent("/identity")
        } else {
            apiURL = environmentUrlData.api ?? URL(string: "https://api.bitwarden.com")!
            baseURL = environmentUrlData.base ?? URL(string: "https://vault.bitwarden.com")!
            eventsURL = environmentUrlData.events ?? URL(string: "https://events.bitwarden.com")!
            identityURL = environmentUrlData.identity ?? URL(string: "https://identity.bitwarden.com")!
        }
    }
}
