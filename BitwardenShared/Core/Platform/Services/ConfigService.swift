import Foundation
import OSLog

// MARK: - ConfigService

/// A protocol for a `ConfigService` that manages the app's config.
///
protocol ConfigService {
    /// Retrieves the current configuration.
    ///
    /// - Parameters:
    ///   - forceRefresh: If true, forces refreshing the configuration from the server.
    /// - Returns: A server configuration if able.
    ///
    func getConfig(forceRefresh: Bool) async -> ServerConfig?

    /// Retrieves a boolean feature flag.
    ///
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool, forceRefresh: Bool) async -> Bool

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int, forceRefresh: Bool) async -> Int

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String?, forceRefresh: Bool) async -> String?
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

    /// Initialize a `DefaultEnvironmentService`.
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
        let localConfig = await stateService.getConfig()

        let localConfigExpired = localConfig?.date.addingTimeInterval(Constants.minimumConfigSyncInterval)
            ?? Date.distantPast
            < timeProvider.presentTime

        if forceRefresh || localConfig == nil || localConfigExpired {
            do {
                let configResponse = try await configApiService.getConfig()
                return ServerConfig(
                    date: timeProvider.presentTime,
                    responseModel: configResponse
                )
            } catch {
                errorReporter.log(error: error)
            }
        }

        // If we are unable to retrieve a configuration from the server,
        // fall back to the local configuration.
        return localConfig
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool = false, forceRefresh: Bool = false) async -> Bool {
        defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int = 0, forceRefresh: Bool = false) async -> Int {
        defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String? = nil, forceRefresh: Bool = false) async -> String? {
        defaultValue
    }

    // MARK: Private Methods

//    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: AnyCodable)
}
