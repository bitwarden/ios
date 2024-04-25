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
    ///
    func getConfig(forceRefresh: Bool) async -> ConfigResponseModel

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

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Private Properties

    let retrievalInterval = 3_600_000 // 1 hour

    // MARK: Initialization

    /// Initialize a `DefaultEnvironmentService`.
    ///
    /// - Parameters:
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(stateService: StateService) {
        self.stateService = stateService
    }

    // MARK: Methods

    func getConfig(forceRefresh: Bool) async -> ConfigResponseModel {
        ConfigResponseModel(environment: nil, featureStates: [:], gitHash: "", server: nil, version: "")
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
