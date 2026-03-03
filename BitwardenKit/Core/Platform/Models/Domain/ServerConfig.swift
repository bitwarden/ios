import BitwardenSdk
import Foundation

// MARK: - ServerConfig

/// Model that represents the configuration provided by the server at a particular time.
///
public struct ServerConfig: Equatable, Codable, Sendable {
    // MARK: Properties

    /// The communication settings.
    public let communication: ServerCommunicationSettings?

    /// The particular time of the server configuration.
    public let date: Date

    /// The environment URLs of the server.
    public let environment: EnvironmentServerConfig?

    /// Feature flags to configure the client.
    public let featureStates: [String: AnyCodable]

    /// The git hash of the server.
    public let gitHash: String?

    /// Third party server information.
    public let server: ThirdPartyServerConfig?

    /// The version of the server.
    public let version: String

    public init(date: Date, responseModel: ConfigResponseModel) {
        communication = responseModel.communication.map(ServerCommunicationSettings.init)
        environment = responseModel.environment.map(EnvironmentServerConfig.init)
        self.date = date
        featureStates = responseModel.featureStates ?? [:]
        gitHash = responseModel.gitHash
        server = responseModel.server.map(ThirdPartyServerConfig.init)
        version = responseModel.version
    }

    // MARK: Methods

    /// Checks if the server is an official Bitwarden server.
    ///
    /// - Returns: `true` if the server is `nil`, indicating an official Bitwarden server, otherwise `false`.
    ///
    public func isOfficialBitwardenServer() -> Bool {
        server == nil
    }
}

// MARK: - ThirdPartyServerConfig

/// Model for third-party configuration of the server.
///
public struct ThirdPartyServerConfig: Equatable, Codable, Sendable {
    /// The name of the third party configuration.
    public let name: String

    /// The URL of the third party configuration.
    public let url: String

    public init(responseModel: ThirdPartyConfigResponseModel) {
        name = responseModel.name
        url = responseModel.url
    }
}

// MARK: - EnvironmentServerConfig

/// Model for the environment URLs in a server configuration.
public struct EnvironmentServerConfig: Equatable, Codable, Sendable {
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

    public init(responseModel: EnvironmentServerConfigResponseModel) {
        api = responseModel.api
        cloudRegion = responseModel.cloudRegion
        identity = responseModel.identity
        notifications = responseModel.notifications
        sso = responseModel.sso
        vault = responseModel.vault
    }
}

// MARK: - CommunicationSettings

/// Server communication configuration settings.
///
public struct ServerCommunicationSettings: Equatable, Codable, Sendable {
    // MARK: Properties

    /// Bootstrap configuration determining how to establish server communication.
    public let bootstrap: ServerCommunicationBootstrapSettings

    // MARK: Initialization

    /// Creates a new communication settings instance.
    ///
    /// - Parameters:
    ///   - bootstrap: Bootstrap configuration determining how to establish server communication.
    ///
    public init(bootstrap: ServerCommunicationBootstrapSettings) {
        self.bootstrap = bootstrap
    }

    public init(responseModel: CommunicationSettingsResponseModel) {
        bootstrap = ServerCommunicationBootstrapSettings(responseModel: responseModel.bootstrap)
    }
}

// MARK: - ServerCommunicationBootstrapSettings

/// Bootstrap configuration settings for server communication.
///
public struct ServerCommunicationBootstrapSettings: Equatable, Codable, Sendable {
    // MARK: Properties

    /// The bootstrap type (e.g. `"ssoCookieVendor"`, `"direct"`).
    public let type: String

    /// Identity provider login URL for browser redirect during bootstrap.
    public let idpLoginUrl: String?

    /// Cookie name (base name, without shard suffix).
    public let cookieName: String?

    /// Cookie domain for validation.
    public let cookieDomain: String?

    // MARK: Initialization

    /// Creates a new bootstrap settings instance.
    ///
    /// - Parameters:
    ///   - type: The bootstrap type.
    ///   - idpLoginUrl: Identity provider login URL for browser redirect during bootstrap.
    ///   - cookieName: Cookie name (base name, without shard suffix).
    ///   - cookieDomain: Cookie domain for validation.
    ///
    public init(
        type: String,
        idpLoginUrl: String?,
        cookieName: String?,
        cookieDomain: String?,
    ) {
        self.type = type
        self.idpLoginUrl = idpLoginUrl
        self.cookieName = cookieName
        self.cookieDomain = cookieDomain
    }

    public init(responseModel: CommunicationBootstrapSettingsResponseModel) {
        type = responseModel.type
        idpLoginUrl = responseModel.idpLoginUrl
        cookieName = responseModel.cookieName
        cookieDomain = responseModel.cookieDomain
    }
}
