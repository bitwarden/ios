import BitwardenKit
import TestHelpers

public class MockConfigStateService: ConfigStateService {
    public var activeAccountId: String?
    public var preAuthServerConfig: ServerConfig?
    public var serverConfig = [String: ServerConfig]()

    public func getActiveAccountId() async throws -> String {
        guard let activeAccountId else { throw BitwardenTestError.example }
        return activeAccountId
    }

    public func getPreAuthServerConfig() async -> ServerConfig? {
        preAuthServerConfig
    }

    public func getServerConfig(userId: String?) async throws -> ServerConfig? {
        let userId = try unwrapUserId(userId)
        return serverConfig[userId]
    }

    public func setPreAuthServerConfig(config: ServerConfig) async {
        preAuthServerConfig = config
    }
   
    public func setServerConfig(_ config: ServerConfig?, userId: String?) async throws {
        let userId = try unwrapUserId(userId)
        serverConfig[userId] = config
    }

    /// Attempts to convert a possible user id into a known account id.
    ///
    /// - Parameter userId: If nil, the active account id is returned. Otherwise, validate the id.
    ///
    func unwrapUserId(_ userId: String?) throws -> String {
        if let userId {
            return userId
        } else if let activeAccountId {
            return activeAccountId
        } else {
            throw BitwardenTestError.example
        }
    }
}
