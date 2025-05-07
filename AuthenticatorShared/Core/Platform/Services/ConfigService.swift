import BitwardenKit
import Combine
import Foundation
import OSLog

// MARK: - DefaultConfigService

/// A default implementation of a `ConfigService` that manages the app's config.
///
class DefaultConfigService: ConfigService {
    // MARK: Properties

    /// The App Settings Store used for storing and retrieving values from User Defaults.
    private let appSettingsStore: AppSettingsStore

    /// The API service to make config requests.
    private let configApiService: ConfigAPIService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// A subject to notify any subscribers of new server configs.
    private let configSubject = CurrentValueSubject<MetaServerConfig?, Never>(nil)

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
        configApiService: ConfigAPIService,
        errorReporter: ErrorReporter,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.appSettingsStore = appSettingsStore
        self.configApiService = configApiService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Methods

    @discardableResult
    func getConfig(forceRefresh: Bool, isPreAuth: Bool) async -> ServerConfig? {
        guard !forceRefresh else {
            await updateConfigFromServer(isPreAuth: isPreAuth)
            return try? await getStateServerConfig(isPreAuth: isPreAuth)
        }

        let localConfig = try? await getStateServerConfig(isPreAuth: isPreAuth)

        let localConfigExpired = localConfig?.date.addingTimeInterval(Constants.minimumConfigSyncInterval)
            ?? Date.distantPast
            < timeProvider.presentTime

        // if it's not forcing refresh we don't need to wait for the server call
        // to finish and we can move it to the background.
        if localConfig == nil || localConfigExpired {
            Task {
                await updateConfigFromServer(isPreAuth: isPreAuth)
            }
        }

        return localConfig
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

        guard flag.isRemotelyConfigured else {
            return flag.initialValue?.boolValue ?? defaultValue
        }
        let configuration = await getConfig(forceRefresh: forceRefresh, isPreAuth: isPreAuth)
        return configuration?.featureStates[flag.rawValue]?.boolValue
            ?? flag.initialValue?.boolValue
            ?? defaultValue
    }

    func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: Int = 0,
        forceRefresh: Bool = false,
        isPreAuth: Bool = false
    ) async -> Int {
        guard flag.isRemotelyConfigured else {
            return flag.initialValue?.intValue ?? defaultValue
        }
        let configuration = await getConfig(forceRefresh: forceRefresh, isPreAuth: isPreAuth)
        return configuration?.featureStates[flag.rawValue]?.intValue
            ?? flag.initialValue?.intValue
            ?? defaultValue
    }

    func getFeatureFlag(
        _ flag: FeatureFlag,
        defaultValue: String? = nil,
        forceRefresh: Bool = false,
        isPreAuth: Bool = false
    ) async -> String? {
        guard flag.isRemotelyConfigured else {
            return flag.initialValue?.stringValue ?? defaultValue
        }
        let configuration = await getConfig(forceRefresh: forceRefresh, isPreAuth: isPreAuth)
        return configuration?.featureStates[flag.rawValue]?.stringValue
            ?? flag.initialValue?.stringValue
            ?? defaultValue
    }

    // MARK: Debug Feature Flags

    func getDebugFeatureFlags(_ flags: [FeatureFlag]) async -> [DebugMenuFeatureFlag] {
        let remoteFeatureFlags = await getConfig()?.featureStates ?? [:]

        let debugFlags = flags.map { feature in
            let userDefaultValue = appSettingsStore.debugFeatureFlag(name: feature.rawValue)
            let remoteFlagValue = remoteFeatureFlags[feature.rawValue]?.boolValue
                ?? feature.initialValue?.boolValue
                ?? false

            return DebugMenuFeatureFlag(
                feature: feature,
                isEnabled: userDefaultValue ?? remoteFlagValue
            )
        }

        return debugFlags
    }

    func toggleDebugFeatureFlag(name: String, newValue: Bool?) async {
        appSettingsStore.overrideDebugFeatureFlag(
            name: name,
            value: newValue
        )
    }

    func refreshDebugFeatureFlags(_ flags: [FeatureFlag]) async -> [DebugMenuFeatureFlag] {
        for flag in flags {
            appSettingsStore.overrideDebugFeatureFlag(
                name: flag.rawValue,
                value: nil
            )
        }
        return await getDebugFeatureFlags(flags)
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

    func configPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<MetaServerConfig?, Never>> {
        configSubject.eraseToAnyPublisher().values
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

    /// Performs a call to the server to get the latest config and updates the local value.
    /// - Parameter isPreAuth: If true, the call is coming before the user is authenticated or when adding a new account
    private func updateConfigFromServer(isPreAuth: Bool) async {
        // The userId is needed here so we know which user trigger getting the config
        // which helps if this is done in background and the user somehow changes the user
        // while this is loading.
        let userId = try? await stateService.getActiveAccountId()

        do {
            let configResponse = try await configApiService.getConfig()
            let serverConfig = ServerConfig(
                date: timeProvider.presentTime,
                responseModel: configResponse
            )
            try? await setStateServerConfig(serverConfig, isPreAuth: isPreAuth, userId: userId)

            configSubject.send(MetaServerConfig(isPreAuth: isPreAuth, userId: userId, serverConfig: serverConfig))
        } catch {
            errorReporter.log(error: error)

            guard !isPreAuth else {
                return
            }

            let localConfig = try? await stateService.getServerConfig(userId: userId)
            guard localConfig == nil,
                  let preAuthConfig = await stateService.getPreAuthServerConfig() else {
                return
            }

            try? await setStateServerConfig(preAuthConfig, isPreAuth: false, userId: userId)
        }
    }
}
