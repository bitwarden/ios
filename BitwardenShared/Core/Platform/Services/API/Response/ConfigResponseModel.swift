import Foundation
import Networking

// MARK: - ConfigResponseModel

/// API response model for the configuration request.
///
struct ConfigResponseModel: Equatable, JSONResponse {
    // MARK: Properties

    /// The environment URLs of the server.
    let environment: EnvironmentServerConfigResponse?

    /// Feature flags to configure the client.
    let featureStates: [String: AnyCodable]

    /// The git hash of the server.
    let gitHash: String

    /// Third party server information.
    let server: ThirdPartyConfigResponseModel?

    /// The version of the server.
    let version: String
}

/// API response model for third party configuration in a configuration response.
struct ThirdPartyConfigResponseModel: Equatable, JSONResponse {
    /// The name of the third party configuration.
    let name: String

    /// The URL of the third party configuration.
    let url: String
}

/// API response model for the environment URLs in a configuration response.
struct EnvironmentServerConfigResponse: Equatable, JSONResponse {
    /// The API URL.
    let api: String

    /// The Cloud Region (e.g. "US")
    let cloudRegion: String

    /// The Identity URL.
    let identity: String

    /// The Notifications URL.
    let notifications: String

    /// The SSO URL.
    let sso: String

    /// The Vault URL.
    let vault: String
}
