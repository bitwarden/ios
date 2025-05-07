import Combine

// MARK: - ConfigService

/// A protocol for a `ConfigService` that manages the app's config.
///
public protocol ConfigService {
    /// A publisher that updates with a new value when a new server configuration is received.
    func configPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<MetaServerConfig?, Never>>

    /// Retrieves the current configuration. This will return the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`. Configurations
    /// retrieved from the server are saved to disk.
    ///
    /// - Parameters:
    ///   - forceRefresh: If true, forces refreshing the configuration from the server.
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account.
    /// - Returns: A server configuration if able.
    ///
    @discardableResult
    func getConfig(forceRefresh: Bool, isPreAuth: Bool) async -> ServerConfig?

    /// Retrieves a boolean feature flag. This will use the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`.
    ///
    /// - Parameters:
    ///   - flag: The feature flag to retrieve
    ///   - defaultValue: The default value to use if the flag is not in the server configuration
    ///   - forceRefresh: If true, forces refreshing the configuration from the server before retrieval
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account.
    /// - Returns: The value for the feature flag
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool, forceRefresh: Bool, isPreAuth: Bool) async -> Bool

    /// Retrieves an integer feature flag. This will use the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`.
    ///
    /// - Parameters:
    ///   - flag: The feature flag to retrieve
    ///   - defaultValue: The default value to use if the flag is not in the server configuration
    ///   - forceRefresh: If true, forces refreshing the configuration from the server before retrieval
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account.
    /// - Returns: The value for the feature flag
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int, forceRefresh: Bool, isPreAuth: Bool) async -> Int

    /// Retrieves a string feature flag. This will use the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`.
    ///
    /// - Parameters:
    ///   - flag: The feature flag to retrieve
    ///   - defaultValue: The default value to use if the flag is not in the server configuration
    ///   - forceRefresh: If true, forces refreshing the configuration from the server before retrieval
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account.
    /// - Returns: The value for the feature flag
    func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: String?,
        forceRefresh: Bool,
        isPreAuth: Bool
    ) async -> String?

    // MARK: Debug Feature Flags

    /// Retrieves the debug menu feature flags.
    ///
    func getDebugFeatureFlags(_ flags: [FeatureFlag]) async -> [DebugMenuFeatureFlag]

    /// Toggles the value of a debug feature flag in the app's settings store.
    ///
    func toggleDebugFeatureFlag(
        name: String,
        newValue: Bool?
    ) async

    /// Refreshes the list of debug feature flags by reloading their values from the settings store.
    ///
    func refreshDebugFeatureFlags(_ flags: [FeatureFlag]) async -> [DebugMenuFeatureFlag]
}

public extension ConfigService {
    /// Retrieves the current configuration. This will return the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`. Configurations
    /// retrieved from the server are saved to disk.
    ///
    /// - Parameters:
    ///   - forceRefresh: If true, forces refreshing the configuration from the server.
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account.
    /// - Returns: A server configuration if able.
    ///
    @discardableResult
    func getConfig(isPreAuth: Bool = false) async -> ServerConfig? {
        await getConfig(forceRefresh: false, isPreAuth: isPreAuth)
    }

    /// Retrieves a boolean feature flag. This will use the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`.
    ///
    /// - Parameters:
    ///   - flag: The feature flag to retrieve
    ///   - defaultValue: The default value to use if the flag is not in the server configuration
    ///   - forceRefresh: If true, forces refreshing the configuration from the server before retrieval
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account.
    /// - Returns: The value for the feature flag
    ///
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool = false, isPreAuth: Bool = false) async -> Bool {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false, isPreAuth: isPreAuth)
    }

    /// Retrieves an integer feature flag. This will use the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`.
    ///
    /// - Parameters:
    ///   - flag: The feature flag to retrieve
    ///   - defaultValue: The default value to use if the flag is not in the server configuration
    ///   - forceRefresh: If true, forces refreshing the configuration from the server before retrieval
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account.
    /// - Returns: The value for the feature flag
    ///
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int = 0, isPreAuth: Bool = false) async -> Int {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false, isPreAuth: isPreAuth)
    }

    /// Retrieves a string feature flag. This will use the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`.
    ///
    /// - Parameters:
    ///   - flag: The feature flag to retrieve
    ///   - defaultValue: The default value to use if the flag is not in the server configuration
    ///   - forceRefresh: If true, forces refreshing the configuration from the server before retrieval
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account.
    /// - Returns: The value for the feature flag
    ///
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String? = nil, isPreAuth: Bool = false) async -> String? {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false, isPreAuth: isPreAuth)
    }
}
