import Foundation

// MARK: - ServerConfig

/// Model that represents the configuration provided by the server at a particular time.
///
struct ServerConfig: Equatable, Codable {
    // MARK: Properties

    /// The environment URLs of the server.
    let environment: EnvironmentServerConfig?

    /// The particular time of the server configuration.
    let date: Date

    /// Feature flags to configure the client.
    let featureStates: [String: AnyCodable]

    /// The git hash of the server.
    let gitHash: String

    /// Third party server information.
    let server: ThirdPartyServerConfig?

    /// The version of the server.
    let version: String

    init(responseModel: ConfigResponseModel, date: Date) {
        environment = EnvironmentServerConfig(responseModel: responseModel.environment)
        self.date = date
        featureStates = responseModel.featureStates
        gitHash = responseModel.gitHash
        server = ThirdPartyServerConfig(responseModel: responseModel.server)
        version = responseModel.version
    }
}

// MARK: - ThirdPartyServerConfig

/// Model for third-party configuration of the server.
///
struct ThirdPartyServerConfig: Equatable, Codable {
    /// The name of the third party configuration.
    let name: String

    /// The URL of the third party configuration.
    let url: String

    init?(responseModel: ThirdPartyConfigResponseModel?) {
        guard let responseModel else { return nil }
        name = responseModel.name
        url = responseModel.url
    }
}

// MARK: - EnvironmentServerConfig

/// Model for the environment URLs in a server configuration.
struct EnvironmentServerConfig: Equatable, Codable {
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

    init?(responseModel: EnvironmentServerConfigResponseModel?) {
        guard let responseModel else { return nil }
        api = responseModel.api
        cloudRegion = responseModel.cloudRegion
        identity = responseModel.identity
        notifications = responseModel.notifications
        sso = responseModel.sso
        vault = responseModel.vault
    }
}
