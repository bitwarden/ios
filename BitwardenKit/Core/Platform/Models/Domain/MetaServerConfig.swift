/// Helper object to send updated server configuration object with extra metadata,
/// like whether it comes from pre-auth and the user ID it belongs to.
/// This is useful for getting the config on background and establishing which was the original context.
public struct MetaServerConfig {
    /// If true, the call is coming before the user is authenticated or when adding a new account.
    public let isPreAuth: Bool

    /// The user ID that requested the server config.
    public let userId: String?

    /// The server config.
    public let serverConfig: ServerConfig?

    /// Initializes a `MetaServerConfig`.
    ///
    /// - Parameters:
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account.
    ///   - userId: The user ID that requested the server configuration.
    ///   - serverConfig: The server configuration.
    public init(isPreAuth: Bool, userId: String?, serverConfig: ServerConfig?) {
        self.isPreAuth = isPreAuth
        self.userId = userId
        self.serverConfig = serverConfig
    }
}
