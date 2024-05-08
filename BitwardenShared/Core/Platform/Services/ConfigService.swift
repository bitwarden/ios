import Foundation
import OSLog

// MARK: - ConfigService

/// A protocol for a `ConfigService` that manages the app's config.
///
protocol ConfigService {
    /// Retrieves the current configuration. This will return the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`. Configurations
    /// retrieved from the server are saved to disk.
    ///
    /// - Parameters:
    ///   - forceRefresh: If true, forces refreshing the configuration from the server.
    /// - Returns: A server configuration if able.
    ///
    func getConfig(forceRefresh: Bool) async -> ServerConfig?

    /// Retrieves a boolean feature flag. This will use the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`.
    ///
    /// - Parameters:
    ///   - flag: The feature flag to retrieve
    ///   - defaultValue: The default value to use if the flag is not in the server configuration
    ///   - forceRefresh: If true, forces refreshing the configuration from the server before retrieval
    /// - Returns: The value for the feature flag
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool, forceRefresh: Bool) async -> Bool

    /// Retrieves an integer feature flag. This will use the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`.
    ///
    /// - Parameters:
    ///   - flag: The feature flag to retrieve
    ///   - defaultValue: The default value to use if the flag is not in the server configuration
    ///   - forceRefresh: If true, forces refreshing the configuration from the server before retrieval
    /// - Returns: The value for the feature flag
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int, forceRefresh: Bool) async -> Int

    /// Retrieves a string feature flag. This will use the on-disk configuration if available,
    /// or will retrieve it from the server if not. It will also retrieve the configuration from
    /// the server if it is outdated or if the `forceRefresh` argument is `true`.
    ///
    /// - Parameters:
    ///   - flag: The feature flag to retrieve
    ///   - defaultValue: The default value to use if the flag is not in the server configuration
    ///   - forceRefresh: If true, forces refreshing the configuration from the server before retrieval
    /// - Returns: The value for the feature flag
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String?, forceRefresh: Bool) async -> String?
}

extension ConfigService {
    func getConfig() async -> ServerConfig? {
        await getConfig(forceRefresh: false)
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool) async -> Bool {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false)
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int) async -> Int {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false)
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String?) async -> String? {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false)
    }
}

// MARK: - DefaultConfigService

/// A default implementation of a `ConfigService` that manages the app's config.
///
class DefaultConfigService: ConfigService {
    // MARK: Properties

    /// The API service to make config requests.
    private let configApiService: ConfigAPIService

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
    ///   - configApiService: The API service to make config requests.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: The services used to get the present time.
    ///
    init(
        configApiService: ConfigAPIService,
        errorReporter: ErrorReporter,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.configApiService = configApiService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    func getConfig(forceRefresh: Bool) async -> ServerConfig? {
        let localConfig = try? await stateService.getServerConfig()

        let localConfigExpired = localConfig?.date.addingTimeInterval(Constants.minimumConfigSyncInterval)
            ?? Date.distantPast
            < timeProvider.presentTime

        if forceRefresh || localConfig == nil || localConfigExpired {
            do {
                let configResponse = try await configApiService.getConfig()
                let serverConfig = ServerConfig(
                    date: timeProvider.presentTime,
                    responseModel: configResponse
                )
                try? await stateService.setServerConfig(serverConfig)
                return serverConfig
            } catch {
                errorReporter.log(error: error)
            }
        }

        // If we are unable to retrieve a configuration from the server,
        // fall back to the local configuration.
        return localConfig
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool = false, forceRefresh: Bool = false) async -> Bool {
        let configuration = await getConfig(forceRefresh: forceRefresh)
        return configuration?.featureStates[flag]?.boolValue ?? defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int = 0, forceRefresh: Bool = false) async -> Int {
        let configuration = await getConfig(forceRefresh: forceRefresh)
        return configuration?.featureStates[flag]?.intValue ?? defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String? = nil, forceRefresh: Bool = false) async -> String? {
        let configuration = await getConfig(forceRefresh: forceRefresh)
        return configuration?.featureStates[flag]?.stringValue ?? defaultValue
    }
}
