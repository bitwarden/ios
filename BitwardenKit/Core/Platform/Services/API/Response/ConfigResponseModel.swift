import Foundation
import Networking

// MARK: - ConfigResponseModel

/// API response model for the configuration request.
///
public struct ConfigResponseModel: Equatable, JSONResponse {
    // MARK: Properties

    /// The environment URLs of the server.
    public let environment: EnvironmentServerConfigResponseModel?

    /// Feature flags to configure the client.
    public let featureStates: [String: AnyCodable]?

    /// The git hash of the server.
    public let gitHash: String?

    /// Third party server information.
    public let server: ThirdPartyConfigResponseModel?

    /// The version of the server.
    public let version: String

    // MARK: Initializers

    /// A public version of the standard synthesized initializer.
    public init(
        environment: EnvironmentServerConfigResponseModel?,
        featureStates: [String: AnyCodable]?,
        gitHash: String?,
        server: ThirdPartyConfigResponseModel?,
        version: String
    ) {
        self.environment = environment
        self.featureStates = featureStates
        self.gitHash = gitHash
        self.server = server
        self.version = version
    }
}

/// API response model for third-party configuration in a configuration response.
public struct ThirdPartyConfigResponseModel: Equatable, JSONResponse {
    /// The name of the third party configuration.
    public let name: String

    /// The URL of the third party configuration.
    public let url: String

    // MARK: Initializers

    /// A public version of the standard synthesized initializer.
    public init(
        name: String,
        url: String
    ) {
        self.name = name
        self.url = url
    }
}

/// API response model for the environment URLs in a configuration response.
public struct EnvironmentServerConfigResponseModel: Equatable, JSONResponse {
    /// The API URL.
    public let api: String?

    /// The Cloud Region (e.g. "US")
    public let cloudRegion: String?

    /// The Identity URL.
    public let identity: String?

    /// The Notifications URL.
    public let notifications: String?

    /// The SSO URL.
    public let sso: String?

    /// The Vault URL.
    public let vault: String?

    // MARK: Initializers

    /// A public version of the standard synthesized initializer.
    public init(
        api: String?,
        cloudRegion: String?,
        identity: String?,
        notifications: String?,
        sso: String?,
        vault: String?
    ) {
        self.api = api
        self.cloudRegion = cloudRegion
        self.identity = identity
        self.notifications = notifications
        self.sso = sso
        self.vault = vault
    }
}
