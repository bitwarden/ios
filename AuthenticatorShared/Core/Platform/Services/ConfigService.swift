import Foundation
import OSLog

// MARK: - ConfigService

/// A protocol for a `ConfigService` that manages the app's config.
/// This is significantly pared down from the `ConfigService` in the PM app.
///
protocol ConfigService {
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
    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool = false) async -> Bool {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false)
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int = 0) async -> Int {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false)
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String? = nil) async -> String? {
        await getFeatureFlag(flag, defaultValue: defaultValue, forceRefresh: false)
    }
}

// MARK: - DefaultConfigService

/// A default implementation of a `ConfigService` that manages the app's config.
///
class DefaultConfigService: ConfigService {
    // MARK: Properties

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    // MARK: Initialization

    /// Initialize a `DefaultConfigService`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: The services used to get the present time.
    ///
    init(
        errorReporter: ErrorReporter
    ) {
        self.errorReporter = errorReporter
    }

    // MARK: Methods

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Bool = false, forceRefresh: Bool = false) async -> Bool {
        FeatureFlag.initialLocalValues[flag]?.boolValue ?? defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: Int = 0, forceRefresh: Bool = false) async -> Int {
        FeatureFlag.initialLocalValues[flag]?.intValue ?? defaultValue
    }

    func getFeatureFlag(_ flag: FeatureFlag, defaultValue: String? = nil, forceRefresh: Bool = false) async -> String? {
        FeatureFlag.initialLocalValues[flag]?.stringValue ?? defaultValue
    }
}
