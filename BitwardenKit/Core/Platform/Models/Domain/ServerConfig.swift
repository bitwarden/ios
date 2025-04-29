import Foundation

// MARK: - ServerConfig

/// Model that represents the configuration provided by the server at a particular time.
///
public struct ServerConfig: Equatable, Codable, Sendable {
    // MARK: Properties

    /// The environment URLs of the server.
    public let environment: EnvironmentServerConfig?

    /// The particular time of the server configuration.
    public let date: Date

    /// Feature flags to configure the client.
    public let featureStates: [String: AnyCodable]

    /// The git hash of the server.
    public let gitHash: String?

    /// Third party server information.
    public let server: ThirdPartyServerConfig?

    /// The version of the server.
    public let version: String

    public init(date: Date, responseModel: ConfigResponseModel) {
        environment = responseModel.environment.map(EnvironmentServerConfig.init)
        self.date = date
        featureStates = responseModel.featureStates ?? [:]
//        let features: [(FeatureFlag, AnyCodable)]
//        features = responseModel.featureStates?.compactMap { key, value in
//            guard let flag = FeatureFlag(rawValue: key) else { return nil }
//            return (flag, value)
//        } ?? []
//        featureStates = Dictionary(uniqueKeysWithValues: features)

        gitHash = responseModel.gitHash
        server = responseModel.server.map(ThirdPartyServerConfig.init)
        version = responseModel.version
    }

    // MARK: Methods

    /// Whether the server supports cipher key encryption.
    ///
    /// - Returns: `true` if it's supported, `false` otherwise.
    ///
//    func supportsCipherKeyEncryption() -> Bool {
//        guard let minVersion = ServerVersion(Constants.cipherKeyEncryptionMinServerVersion),
//              let serverVersion = ServerVersion(version),
//              minVersion <= serverVersion else {
//            return false
//        }
//        return true
//    }

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
