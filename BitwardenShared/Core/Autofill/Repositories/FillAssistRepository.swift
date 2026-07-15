import BitwardenKit
import CryptoKit
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

    /// Clears all cached fill-assist data for an account.
    ///
    /// - Parameter userId: The user ID of the account to clear. Defaults to the active account if `nil`.
    ///
    func clearRules(userId: String?) async throws
}

// MARK: - FillAssistFingerprintError

/// Errors thrown while computing the fill-assist cached-rules integrity fingerprint.
///
private enum FillAssistFingerprintError: Error {
    /// The cached data could not be encoded to compute its fingerprint.
    case encodingFailed
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

    /// The repository for storing the cached-rules integrity fingerprint.
    private let keychainRepository: KeychainRepository

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
    ///   - keychainRepository: The repository for storing the cached-rules integrity fingerprint.
    ///   - stateService: The service for accessing account state.
    ///   - timeProvider: The provider of the current time.
    ///
    init(
        appSettingsStore: AppSettingsStore,
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        fillAssistAPIService: FillAssistAPIService,
        keychainRepository: KeychainRepository,
        stateService: StateService,
        timeProvider: TimeProvider,
    ) {
        self.appSettingsStore = appSettingsStore
        self.configService = configService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.fillAssistAPIService = fillAssistAPIService
        self.keychainRepository = keychainRepository
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
        return await loadVerifiedCachedData(userId: userId)?.rules[hostname]
    }

    func clearRules(userId: String?) async throws {
        let resolvedUserId: String = if let userId {
            userId
        } else {
            try await stateService.getActiveAccountId()
        }
        appSettingsStore.setFillAssistCachedData(nil, userId: resolvedUserId)
        appSettingsStore.setFillAssistLastFetchTimestamp(nil, userId: resolvedUserId)
        try await keychainRepository.deleteUserAuthKey(for: .fillAssistRulesFingerprint(userId: resolvedUserId))
    }

    // MARK: Private

    /// Runs the full sync pipeline if sync conditions are met
    ///
    private func performSync() async throws {
        guard await configService.getFeatureFlag(.fillAssistTargetingRules),
              try await stateService.getFillAssistEnabled() else { return }

        let sourceUrl = environmentService.fillAssistRulesURL
        let userId = try await stateService.getActiveAccountId()
        let cached = await loadVerifiedCachedData(userId: userId)
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

        if let newFingerprint = try? fingerprint(for: data) {
            do {
                try await keychainRepository.setUserAuthKey(
                    for: .fillAssistRulesFingerprint(userId: userId),
                    value: newFingerprint,
                )
            } catch {
                errorReporter.log(error: error)
            }
        } else {
            errorReporter.log(error: FillAssistFingerprintError.encodingFailed)
        }
    }

    /// Loads the cached fill-assist data for `userId` and verifies its integrity fingerprint,
    /// clearing both the cached data and its fingerprint if they're missing, inconsistent, or
    /// tampered.
    ///
    /// - Parameter userId: The user ID whose cache to load and verify.
    /// - Returns: The verified `FillAssistCachedData`, or `nil` if absent or tampered.
    ///
    private func loadVerifiedCachedData(userId: String) async -> FillAssistCachedData? {
        guard let cached = appSettingsStore.fillAssistCachedData(userId: userId) else {
            // No cached data — clear any stray fingerprint left from an inconsistent prior state.
            try? await keychainRepository.deleteUserAuthKey(for: .fillAssistRulesFingerprint(userId: userId))
            return nil
        }

        let storedFingerprint = try? await keychainRepository.getUserAuthKeyValue(
            for: .fillAssistRulesFingerprint(userId: userId),
        )

        guard let storedFingerprint,
              let computed = try? fingerprint(for: cached),
              storedFingerprint == computed
        else {
            appSettingsStore.setFillAssistCachedData(nil, userId: userId)
            try? await keychainRepository.deleteUserAuthKey(for: .fillAssistRulesFingerprint(userId: userId))
            return nil
        }

        return cached
    }

    /// Computes a SHA-256 integrity fingerprint for the given cached data, using a sorted-keys
    /// JSON encoding so the result is deterministic regardless of dictionary iteration order.
    /// A fresh encoder is created per call since `JSONEncoder` isn't documented as safe for
    /// concurrent use across calls on a shared instance.
    ///
    /// - Parameter data: The cached data to fingerprint.
    /// - Returns: A lowercase hexadecimal SHA-256 digest of the encoded data.
    ///
    private func fingerprint(for data: FillAssistCachedData) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(data).generatedHash(using: SHA256.self)
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
