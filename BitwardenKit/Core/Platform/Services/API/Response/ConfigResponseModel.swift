import Foundation
import Networking

// MARK: - ConfigResponseModel

/// API response model for the configuration request.
///
public struct ConfigResponseModel: Equatable, JSONResponse {
    // MARK: Properties

    /// The communication settings.
    public let communication: CommunicationSettingsResponseModel?

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

    /// Initializes a `ConfigResponseModel`.
    ///
    /// - Parameters:
    ///   - communication: The communication settings.
    ///   - environment: The environment URLs of the server.
    ///   - featureStates: Feature flags to configure the client.
    ///   - gitHash: The git hash of the server.
    ///   - server: Third party server information.
    ///   - version: The version of the server.
    public init(
        communication: CommunicationSettingsResponseModel?,
        environment: EnvironmentServerConfigResponseModel?,
        featureStates: [String: AnyCodable]?,
        gitHash: String?,
        server: ThirdPartyConfigResponseModel?,
        version: String,
    ) {
        self.communication = communication
        self.environment = environment
        self.featureStates = featureStates
        self.gitHash = gitHash
        self.server = server
        self.version = version
    }
}

// MARK: - CommunicationSettingsResponseModel

/// Server communication configuration settings.
///
public struct CommunicationSettingsResponseModel: Equatable, Codable, Sendable {
    // MARK: Properties

    /// Bootstrap configuration determining how to establish server communication.
    public let bootstrap: String

    /// SSO cookie vendor settings for load balancer authentication.
    public let ssoCookieVendor: SsoCookieVendorSettingsResponseModel?

    // MARK: Initialization

    /// Creates a new communication settings instance.
    ///
    /// - Parameters:
    ///   - bootstrap: Bootstrap configuration determining how to establish server communication.
    ///   - ssoCookieVendor: SSO cookie vendor settings for load balancer authentication.
    ///
    public init(
        bootstrap: String,
        ssoCookieVendor: SsoCookieVendorSettingsResponseModel?,
    ) {
        self.bootstrap = bootstrap
        self.ssoCookieVendor = ssoCookieVendor
    }
}

// MARK: - SsoCookieVendorSettingsResponseModel

/// SSO cookie vendor configuration settings.
///
/// This configuration is provided by the server for load balancer authentication.
///
public struct SsoCookieVendorSettingsResponseModel: Equatable, Codable, Sendable {
    // MARK: Properties

    /// Identity provider login URL for browser redirect during bootstrap.
    public let idpLoginUrl: String

    /// Cookie name (base name, without shard suffix).
    public let cookieName: String

    /// Cookie domain for validation.
    public let cookieDomain: String

    // MARK: Initialization

    /// Creates a new SSO cookie vendor settings instance.
    ///
    /// - Parameters:
    ///   - idpLoginUrl: Identity provider login URL for browser redirect during bootstrap.
    ///   - cookieName: Cookie name (base name, without shard suffix).
    ///   - cookieDomain: Cookie domain for validation.
    ///
    public init(
        idpLoginUrl: String,
        cookieName: String,
        cookieDomain: String,
    ) {
        self.idpLoginUrl = idpLoginUrl
        self.cookieName = cookieName
        self.cookieDomain = cookieDomain
    }
}

// MARK: - ThirdPartyConfigResponseModel

/// API response model for third-party configuration in a configuration response.
public struct ThirdPartyConfigResponseModel: Equatable, JSONResponse {
    /// The name of the third-party configuration.
    public let name: String

    /// The URL of the third-party configuration.
    public let url: String

    // MARK: Initializers

    /// Initializes a `ThirdPartyConfigResponseModel`.
    ///
    /// - Parameters:
    ///   - name: The name of the third-party configuration.
    ///   - url: The URL of the third-party configuration.
    public init(
        name: String,
        url: String,
    ) {
        self.name = name
        self.url = url
    }
}

// MARK: - EnvironmentServerConfigResponseModel

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

    /// Initializes an `EnvironmentServerConfigResponseModel`.
    ///
    /// - Parameters:
    ///   - api: The API URL.
    ///   - cloudRegion: The Cloud Region (e.g. "US").
    ///   - identity: The Identity URL.
    ///   - notifications: The Notifications URL.
    ///   - sso: The SSO URL.
    ///   - vault: The Vault URL.
    public init(
        api: String?,
        cloudRegion: String?,
        identity: String?,
        notifications: String?,
        sso: String?,
        vault: String?,
    ) {
        self.api = api
        self.cloudRegion = cloudRegion
        self.identity = identity
        self.notifications = notifications
        self.sso = sso
        self.vault = vault
    }
}
