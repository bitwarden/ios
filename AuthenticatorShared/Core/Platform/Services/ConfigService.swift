import Combine
import Foundation
import OSLog

// MARK: - ConfigService

/// A protocol for a `ConfigService` that manages the app's config.
/// This is significantly pared down from the `ConfigService` in the PM app.
///
protocol ConfigService {
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
    func getDebugFeatureFlags() async -> [DebugMenuFeatureFlag]

    /// Toggles the value of a debug feature flag in the app's settings store.
    ///
    func toggleDebugFeatureFlag(
        name: String,
        newValue: Bool?
    ) async -> [DebugMenuFeatureFlag]

    /// Refreshes the list of debug feature flags by reloading their values from the settings store.
    ///
    func refreshDebugFeatureFlags() async -> [DebugMenuFeatureFlag]
}

extension ConfigService {
    @discardableResult
    func getConfig(isPreAuth: Bool = false) async -> ServerConfig? {
        await getConfig(forceRefresh: false, isPreAuth: isPreAuth)
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool = false, isPreAuth: Bool = false) async -> Bool {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false, isPreAuth: isPreAuth)
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int = 0, isPreAuth: Bool = false) async -> Int {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false, isPreAuth: isPreAuth)
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String? = nil, isPreAuth: Bool = false) async -> String? {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false, isPreAuth: isPreAuth)
    }
}

// MARK: - DefaultConfigService

/// A default implementation of a `ConfigService` that manages the app's config.
///
class DefaultConfigService: ConfigService {
    // MARK: Properties

    /// The App Settings Store used for storing and retrieving values from User Defaults.
    private let appSettingsStore: AppSettingsStore

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize a `DefaultConfigService`.
    ///
    /// - Parameters:
    ///   - appSettingsStore: The App Settings Store used for storing and retrieving values from User Defaults.
    ///   - configApiService: The API service to make config requests.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: The services used to get the present time.
    ///
    init(
        appSettingsStore: AppSettingsStore,
        errorReporter: ErrorReporter,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.appSettingsStore = appSettingsStore
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    @discardableResult
    func getConfig(forceRefresh: Bool, isPreAuth: Bool) async -> ServerConfig? {
        nil
    }

    func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: Bool = false,
        forceRefresh: Bool = false,
        isPreAuth: Bool = false
    ) async -> Bool {
        #if DEBUG_MENU
        if let userDefaultValue = appSettingsStore.debugFeatureFlag(name: flag.rawValue) {
            return userDefaultValue
        }
        #endif

        return FeatureFlag.initialValues[flag]?.boolValue
            ?? defaultValue
    }

    func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: Int = 0,
        forceRefresh: Bool = false,
        isPreAuth: Bool = false
    ) async -> Int {
        FeatureFlag.initialValues[flag]?.intValue
            ?? defaultValue
    }

    func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: String? = nil,
        forceRefresh: Bool = false,
        isPreAuth: Bool = false
    ) async -> String? {
        FeatureFlag.initialValues[flag]?.stringValue
            ?? defaultValue
    }

    func getDebugFeatureFlags() async -> [DebugMenuFeatureFlag] {
        let remoteFeatureFlags = await getConfig()?.featureStates ?? [:]

        let flags = FeatureFlag.debugMenuFeatureFlags.map { feature in
            let userDefaultValue = appSettingsStore.debugFeatureFlag(name: feature.rawValue)
            let remoteFlagValue = remoteFeatureFlags[feature]?.boolValue ?? false

            return DebugMenuFeatureFlag(
                feature: feature,
                isEnabled: userDefaultValue ?? remoteFlagValue
            )
        }

        return flags
    }

    func toggleDebugFeatureFlag(name: String, newValue: Bool?) async -> [DebugMenuFeatureFlag] {
        appSettingsStore.overrideDebugFeatureFlag(
            name: name,
            value: newValue
        )
        return await getDebugFeatureFlags()
    }

    func refreshDebugFeatureFlags() async -> [DebugMenuFeatureFlag] {
        for feature in FeatureFlag.debugMenuFeatureFlags {
            appSettingsStore.overrideDebugFeatureFlag(
                name: feature.rawValue,
                value: nil
            )
        }
        return await getDebugFeatureFlags()
    }

    // MARK: Private

    /// Gets the server config in state depending on if the call is being done before authentication.
    /// - Parameters:
    ///   - config: Config to set
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account
    func getStateServerConfig(isPreAuth: Bool) async throws -> ServerConfig? {
        guard !isPreAuth else {
            return await stateService.getPreAuthServerConfig()
        }
        return try? await stateService.getServerConfig()
    }

    /// Sets the server config in state depending on if the call is being done before authentication.
    /// - Parameters:
    ///   - config: Config to set
    ///   - isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account
    ///   - userId: The userId to set the server config to.
    func setStateServerConfig(_ config: ServerConfig, isPreAuth: Bool, userId: String? = nil) async throws {
        guard !isPreAuth else {
            await stateService.setPreAuthServerConfig(config: config)
            return
        }
        try? await stateService.setServerConfig(config, userId: userId)
    }
}
