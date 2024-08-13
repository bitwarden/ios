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
    let featureStates: [FeatureFlag: AnyCodable]

    /// The git hash of the server.
    let gitHash: String

    /// Third party server information.
    let server: ThirdPartyServerConfig?

    /// The version of the server.
    let version: String

    init(date: Date, responseModel: ConfigResponseModel) {
        environment = responseModel.environment.map(EnvironmentServerConfig.init)
        self.date = date
        let features: [(FeatureFlag, AnyCodable)]
        features = responseModel.featureStates.compactMap { key, value in
            guard let flag = FeatureFlag(rawValue: key) else { return nil }
            return (flag, value)
        }
        featureStates = Dictionary(uniqueKeysWithValues: features)

        gitHash = responseModel.gitHash
        server = responseModel.server.map(ThirdPartyServerConfig.init)
        version = responseModel.version
    }

    func isServerVersionAfter() -> Bool {
        let cleanServerVersion = version.split(separator: "-").first ?? ""
        let cleanMinServerVersion = Constants.CipherKeyEncryptionMinServerVersion.split(separator: "-").first ?? ""

        let serverVersion = cleanServerVersion.split(separator: ".").map { Int($0) ?? 0 }
        let minServerVersion = cleanMinServerVersion.split(separator: ".").map { Int($0) ?? 0 }

        if serverVersion.isEmpty || minServerVersion.isEmpty {
            return false
        }

        for (serverV, minServerV) in zip(serverVersion, minServerVersion) {
            if serverV < minServerV {
                return false
            } else if serverV > minServerV {
                return true
            }
        }

        return serverVersion.count >= minServerVersion.count
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

    init(responseModel: ThirdPartyConfigResponseModel) {
        name = responseModel.name
        url = responseModel.url
    }
}

// MARK: - EnvironmentServerConfig

/// Model for the environment URLs in a server configuration.
struct EnvironmentServerConfig: Equatable, Codable {
    /// The API URL.
    let api: String?

    /// The Cloud Region (e.g. "US")
    let cloudRegion: String?

    /// The Identity URL.
    let identity: String?

    /// The Notifications URL.
    let notifications: String?

    /// The SSO URL.
    let sso: String?

    /// The Vault URL.
    let vault: String?

    init(responseModel: EnvironmentServerConfigResponseModel) {
        api = responseModel.api
        cloudRegion = responseModel.cloudRegion
        identity = responseModel.identity
        notifications = responseModel.notifications
        sso = responseModel.sso
        vault = responseModel.vault
    }
}
