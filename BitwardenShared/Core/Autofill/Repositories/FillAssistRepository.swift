import BitwardenKit
import Foundation

// MARK: - FillAssistRepository

/// A protocol for a repository that manages fetching and caching fill-assist targeting rules.
///
protocol FillAssistRepository { // sourcery: AutoMockable
    /// Fetches and caches fill-assist rules for the active account.
    ///
    func syncRules() async

    /// Returns the cached fill-assist rules for a given hostname, or `nil` if unavailable.
    ///
    /// - Parameter hostname: The hostname to look up.
    /// - Returns: The cached `FillAssistHostRules`, or `nil`.
    ///
    func rules(for hostname: String) async -> FillAssistHostRules?

    /// Clears all cached fill-assist data for the active account.
    ///
    func clearRules() async throws
}

// MARK: - DefaultFillAssistRepository

/// The default implementation of `FillAssistRepository`.
///
class DefaultFillAssistRepository: FillAssistRepository {
    // MARK: Private Properties

    /// The store for persisting fill-assist cached data.
    private let appSettingsStore: AppSettingsStore

    /// The service for checking feature flags and configuration.
    private let configService: ConfigService

    /// The service for reporting non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service for accessing environment URLs.
    private let environmentService: EnvironmentService

    /// The API service for fetching fill-assist data.
    private let fillAssistAPIService: FillAssistAPIService

    /// The service for accessing account state.
    private let stateService: StateService

    /// The provider of the current time, used for interval checks.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Creates a `DefaultFillAssistRepository`.
    ///
    /// - Parameters:
    ///   - appSettingsStore: The store for persisting fill-assist cached data.
    ///   - configService: The service for checking feature flags and configuration.
    ///   - environmentService: The service for accessing environment URLs.
    ///   - errorReporter: The service for reporting non-fatal errors.
    ///   - fillAssistAPIService: The API service for fetching fill-assist data.
    ///   - stateService: The service for accessing account state.
    ///   - timeProvider: The provider of the current time.
    ///
    init(
        appSettingsStore: AppSettingsStore,
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        fillAssistAPIService: FillAssistAPIService,
        stateService: StateService,
        timeProvider: TimeProvider,
    ) {
        self.appSettingsStore = appSettingsStore
        self.configService = configService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.fillAssistAPIService = fillAssistAPIService
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: FillAssistRepository

    func syncRules() async {
        do {
            try await performSync()
        } catch {
            // Sync failures are non-fatal — existing cache remains available.
            errorReporter.log(error: error)
        }
    }

    func rules(for hostname: String) async -> FillAssistHostRules? {
        guard let userId = try? await stateService.getActiveAccountId() else { return nil }
        return appSettingsStore.fillAssistCachedData(userId: userId)?.rules[hostname]
    }

    func clearRules() async throws {
        let userId = try await stateService.getActiveAccountId()
        appSettingsStore.setFillAssistCachedData(nil, userId: userId)
    }

    // MARK: Private

    /// Runs the full sync pipeline if sync conditions are met
    ///
    private func performSync() async throws {
        guard await configService.getFeatureFlag(.fillAssistTargetingRules),
              try await stateService.getFillAssistEnabled() else { return }

        let sourceUrl = environmentService.fillAssistRulesURL
        let userId = try await stateService.getActiveAccountId()
        let cached = appSettingsStore.fillAssistCachedData(userId: userId)
        let lastFetch = appSettingsStore.fillAssistLastFetchTimestamp(userId: userId)
        if let lastFetch,
           cached != nil,
           timeProvider.presentTime.timeIntervalSince(lastFetch) < Constants.FillAssist.updateInterval {
            return
        }

        let manifest = try await fillAssistAPIService.getManifest()

        guard let entry = manifest.maps["forms"]?[Constants.FillAssist.formsVersion],
              !entry.deprecated
        else { return }

        if cached?.cid == entry.cid, cached?.sourceUrl == sourceUrl.absoluteString {
            appSettingsStore.setFillAssistLastFetchTimestamp(timeProvider.presentTime, userId: userId)
            return
        }

        let formsMap = try await fillAssistAPIService.getFormsMap(filename: entry.filename)

        let schemaMajor = formsMap.schemaVersion.split(separator: ".").first.map(String.init) ?? ""
        guard schemaMajor == Constants.FillAssist.expectedSchemaMajor else {
            appSettingsStore.setFillAssistLastFetchTimestamp(timeProvider.presentTime, userId: userId)
            return
        }

        let rules = buildRules(from: formsMap)
        let data = FillAssistCachedData(cid: entry.cid, rules: rules, sourceUrl: sourceUrl.absoluteString)
        appSettingsStore.setFillAssistCachedData(data, userId: userId)
        appSettingsStore.setFillAssistLastFetchTimestamp(timeProvider.presentTime, userId: userId)
    }

    /// Builds a `[hostname: FillAssistHostRules]` dictionary by pooling all non-null field
    /// definitions across each host's top-level forms and every pathname entry.
    ///
    private func buildRules(from formsMap: FormsMapResponseModel) -> [String: FillAssistHostRules] {
        var result = [String: FillAssistHostRules]()
        for (hostname, hostEntry) in formsMap.hosts {
            var pooled = [String: [FillAssistFieldAttributes]]()
            let allForms = hostEntry.allForms
            for form in allForms {
                for (fieldKey, selectors) in form.fields {
                    let attrs = selectors.flatMap(\.attributes)
                    pooled[fieldKey, default: []].append(contentsOf: attrs)
                }
            }
            pooled = pooled.filter { !$0.value.isEmpty }
            if !pooled.isEmpty {
                result[hostname] = FillAssistHostRules(fields: pooled)
            }
        }
        return result
    }
}
