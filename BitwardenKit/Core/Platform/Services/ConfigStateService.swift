public protocol ConfigStateService: ActiveAccountStateProvider {
    /// Gets the server config used by the app prior to the user authenticating.
    /// - Returns: The server config used prior to user authentication.
    func getPreAuthServerConfig() async -> ServerConfig?

    /// Gets the server config for a user ID, as set by the server.
    ///
    /// - Parameter userId: The user ID associated with the server config. Defaults to the active account if `nil`.
    /// - Returns: The user's server config.
    ///
    func getServerConfig(userId: String?) async throws -> ServerConfig?

    /// Sets the server config used prior to user authentication
    /// - Parameter config: The server config to use prior to user authentication.
    func setPreAuthServerConfig(config: ServerConfig) async

    /// Sets the server configuration as provided by a server for a user ID.
    ///
    /// - Parameters:
    ///   - configModel: The config values to set as provided by the server.
    ///   - userId: The user ID associated with the server config.
    ///
    func setServerConfig(_ config: ServerConfig?, userId: String?) async throws
}

public extension ConfigStateService {
    /// Gets the server config for the active account.
    ///
    /// - Returns: The server config sent by the server for the active account.
    ///
    func getServerConfig() async throws -> ServerConfig? {
        try await getServerConfig(userId: getActiveAccountId())
    }

    /// Sets the server config for the active account.
    ///
    /// - Parameter config: The server config.
    ///
    func setServerConfig(_ config: ServerConfig?) async throws {
        try await setServerConfig(config, userId: nil)
    }
}
