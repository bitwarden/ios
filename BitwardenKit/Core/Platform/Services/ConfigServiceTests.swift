import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenKit

@MainActor
struct ConfigServiceTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let appSettingsStore: MockConfigSettingsStore
    let configApiService: MockConfigAPIService
    let errorReporter: MockErrorReporter
    let stateService: MockConfigStateService
    let subject: DefaultConfigService
    let timeProvider: MockTimeProvider

    // MARK: Setup & Teardown

    init() {
        let now = Date(year: 2024, month: 2, day: 14, hour: 8, minute: 0, second: 0)
        appSettingsStore = MockConfigSettingsStore()
        configApiService = MockConfigAPIService()
        errorReporter = MockErrorReporter()
        stateService = MockConfigStateService()
        timeProvider = MockTimeProvider(.mockTime(now))
        subject = DefaultConfigService(
            appSettingsStore: appSettingsStore,
            configApiService: configApiService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider,
        )
        stateService.activeAccountId = "1"
    }

    // MARK: Tests - getConfig remote interactions

    /// `getConfig(forceRefresh:isPreAuth:)` gets the configuration from the server if `forceRefresh` is true
    @Test
    func getConfig_local_forceRefresh() async throws {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        configApiService.clientResult = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: false)
        #expect(configApiService.clientRequestCount == 1)
        #expect(response?.gitHash == "75238191")

        try await assertConfigPublisherWith(isPreAuth: false, userId: "1", gitHash: "75238191")
    }

    /// `getConfig(forceRefresh:isPreAuth:)` gets the local config when server throws if `forceRefresh` is true
    @Test
    func getConfig_local_forceRefreshServerCallThrowing() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        configApiService.clientResult = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: false)
        #expect(configApiService.clientRequestCount == 1)
        #expect(response?.gitHash == "75238192")
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `getConfig(forceRefresh:isPreAuth:)` uses the local configuration if it is expired
    /// but updates the local config when the http request finishes.
    @Test
    func getConfig_local_expired() async throws {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 10, hour: 8, minute: 0, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        configApiService.clientResult = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
        #expect(response?.gitHash == "75238192")

        try await waitForAsync {
            stateService.serverConfig["1"]?.gitHash == "75238191"
        }

        #expect(stateService.serverConfig["1"]?.gitHash == "75238191")

        try await assertConfigPublisherWith(isPreAuth: false, userId: "1", gitHash: "75238191")
    }

    /// `getConfig(forceRefresh:isPreAuth:)` uses the local configuration if it is expired
    /// but updates the local config when the http request finishes.
    @Test
    func getConfig_local_expiredAndServerCallThrowing() async throws {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 10, hour: 8, minute: 0, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        configApiService.clientResult = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
        #expect(response?.gitHash == "75238192")

        try await waitForAsync {
            !errorReporter.errors.isEmpty
        }

        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `getConfig(forceRefresh:isPreAuth:)` uses the local configuration if it's not expired
    @Test
    func getConfig_local_notExpired() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
        #expect(configApiService.clientRequestCount == 0)
        #expect(response?.gitHash == "75238192")
    }

    /// `getConfig(forceRefresh:isPreAuth:)` gets the configuration from the server if there is no local configuration
    ///  but in background returning nil to the caller as is the current available local config.
    @Test
    func getConfig_noLocal() async throws {
        configApiService.clientResult = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
        #expect(response == nil)

        try await waitForAsync {
            stateService.serverConfig["1"] != nil
        }

        #expect(stateService.serverConfig["1"]?.gitHash == "75238191")
        #expect(
            stateService.serverConfig["1"]?.featureStates[FeatureFlag.testFeatureFlag.rawValue] == .bool(true),
        )
    }

    /// `getConfig(forceRefresh:isPreAuth:)` gets the configuration from the pre authenticated server
    /// config if `forceRefresh` is true, there is no local config and there's a pre authenticated server config.
    /// It also updates the local config with the pre authenticated server config.
    @Test
    func getConfig_forceRefreshServerCallThrowingWithPreAuthConfig() async {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        configApiService.clientResult = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: false)
        #expect(configApiService.clientRequestCount == 1)
        #expect(response?.gitHash == "75238192")
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(stateService.serverConfig["1"]?.gitHash == "75238192")
    }

    /// `getConfig(forceRefresh:isPreAuth:)` returns `nil` if `forceRefresh` is true,
    /// there is no local config nor a pre authenticated server config.
    @Test
    func getConfig_forceRefreshServerCallThrowingWithoutPreAuthConfig() async {
        configApiService.clientResult = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: false)
        #expect(configApiService.clientRequestCount == 1)
        #expect(response == nil)
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
        #expect(stateService.serverConfig["1"] == nil)
        #expect(stateService.preAuthServerConfig == nil)
    }

    // MARK: Tests - getConfig pre-auth

    /// `getConfig(forceRefresh:isPreAuth:)` gets the configuration from the server if `forceRefresh` is true
    /// and the user has not been authenticated.
    @Test
    func getConfig_local_forceRefreshPreAuth() async throws {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        configApiService.clientResult = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: true)
        #expect(configApiService.clientRequestCount == 1)
        #expect(response?.gitHash == "75238191")
        #expect(stateService.preAuthServerConfig?.gitHash == "75238191")

        try await assertConfigPublisherWith(isPreAuth: true, userId: "1", gitHash: "75238191")
    }

    /// `getConfig(forceRefresh:isPreAuth:)` uses the local configuration if it is expired
    /// and the user has not been authenticated
    /// but updates the local config when the http request finishes.
    @Test
    func getConfig_local_expiredPreAuth() async throws {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 10, hour: 8, minute: 0, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        configApiService.clientResult = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: true)
        #expect(response?.gitHash == "75238192")

        try await waitForAsync {
            stateService.preAuthServerConfig?.gitHash == "75238191"
        }

        #expect(stateService.preAuthServerConfig?.gitHash == "75238191")

        try await assertConfigPublisherWith(isPreAuth: true, userId: "1", gitHash: "75238191")
    }

    /// `getConfig(forceRefresh:isPreAuth:)` uses the local configuration if it is expired, server throws
    /// and the user has not been authenticated
    /// but updates the local config when the http request finishes.
    @Test
    func getConfig_local_expiredAndServerCallThrowingPreAuth() async throws {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 10, hour: 8, minute: 0, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        configApiService.clientResult = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: true)
        #expect(response?.gitHash == "75238192")

        try await waitForAsync {
            !errorReporter.errors.isEmpty
        }

        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `getConfig(forceRefresh:isPreAuth:)` uses the local configuration if it's not expired
    /// and the user has not been authenticated
    @Test
    func getConfig_local_notExpiredPreAuth() async {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0",
            ),
        )
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: true)
        #expect(configApiService.clientRequestCount == 0)
        #expect(response?.gitHash == "75238192")
        #expect(stateService.preAuthServerConfig?.gitHash == "75238192")
    }

    /// `getConfig(forceRefresh:isPreAuth:)` gets the configuration from the server if there is no local configuration
    /// and the user has not been authenticated
    /// but in background returning nil to the caller as is the current available local config.
    @Test
    func getConfig_noLocalPreAuth() async throws {
        configApiService.clientResult = .httpSuccess(testData: .validServerConfig)
        var configUpdates = await subject.configPublisher().makeAsyncIterator()
        // AsyncPublisher uses demand-based delivery (.max(1) per next() call). Consuming the
        // initial nil here replenishes demand to 1 before the background fetch fires, so the
        // subsequent MetaServerConfig emission is delivered rather than dropped.
        _ = await configUpdates.next()

        let response = await subject.getConfig(forceRefresh: false, isPreAuth: true)
        #expect(response == nil)

        let wrappedMetaConfig = await configUpdates.next()
        let optionalMetaConfig = try #require(wrappedMetaConfig)
        let metaConfig = try #require(optionalMetaConfig)
        #expect(metaConfig.isPreAuth)
        #expect(metaConfig.serverConfig?.gitHash == "75238191")
        #expect(
            metaConfig.serverConfig?.featureStates[FeatureFlag.testFeatureFlag.rawValue] == .bool(true),
        )
    }

    // MARK: Tests - getFeatureFlag initial values

    /// `getFeatureFlag(_:defaultValue:forceRefresh:)` returns the initial value for booleans if it is configured.
    @Test
    func getFeatureFlag_initialValue_localBool() async {
        let value = await subject.getFeatureFlag(
            .testInitialBoolFlag,
            defaultValue: false,
            forceRefresh: false,
        )
        #expect(value)
    }

    /// `getFeatureFlag(_:defaultValue:forceRefresh:)` returns the initial value for integers if it is configured.
    @Test
    func getFeatureFlag_initialValue_localInt() async {
        let value = await subject.getFeatureFlag(
            .testInitialIntFlag,
            defaultValue: 10,
            forceRefresh: false,
        )
        #expect(value == 42)
    }

    /// `getFeatureFlag(_:defaultValue:forceRefresh:)` returns the initial value for strings if it is configured.
    @Test
    func getFeatureFlag_initialValue_localString() async {
        let value = await subject.getFeatureFlag(
            .testInitialStringFlag,
            defaultValue: "Default",
            forceRefresh: false,
        )
        #expect(value == "Test String")
    }

    // MARK: Tests - getFeatureFlag

    /// `getFeatureFlag(_:defaultValue:forceRefresh:)` can return a boolean if it's in the configuration
    @Test
    func getFeatureFlag_bool_exists() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: ["test-feature-flag": .bool(true)],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0",
            ),
        )
        let value = await subject.getFeatureFlag(.testFeatureFlag, defaultValue: false, forceRefresh: false)
        #expect(value)
    }

    /// `getFeatureFlag(_:defaultValue:forceRefresh:)` returns the default value for booleans
    @Test
    func getFeatureFlag_bool_fallback() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0",
            ),
        )
        let value = await subject.getFeatureFlag(.testFeatureFlag, defaultValue: true, forceRefresh: false)
        #expect(value)
    }

    /// `getFeatureFlag(_:defaultValue:forceRefresh:)` can return an integer if it's in the configuration
    @Test
    func getFeatureFlag_int_exists() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: ["test-feature-flag": .int(42)],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0",
            ),
        )
        let value = await subject.getFeatureFlag(.testFeatureFlag, defaultValue: 30, forceRefresh: false)
        #expect(value == 42)
    }

    /// `getFeatureFlag(_:defaultValue:forceRefresh:)` returns the default value for integers
    @Test
    func getFeatureFlag_int_fallback() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0",
            ),
        )
        let value = await subject.getFeatureFlag(.testFeatureFlag, defaultValue: 30, forceRefresh: false)
        #expect(value == 30)
    }

    /// `getFeatureFlag(_:defaultValue:forceRefresh:)` can return a string if it's in the configuration
    @Test
    func getFeatureFlag_string_exists() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: ["test-feature-flag": .string("exists")],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0",
            ),
        )
        let value = await subject.getFeatureFlag(.testFeatureFlag, defaultValue: "fallback", forceRefresh: false)
        #expect(value == "exists")
    }

    /// `getFeatureFlag(_:defaultValue:forceRefresh:)` returns the default value for strings
    @Test
    func getFeatureFlag_string_fallback() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0",
            ),
        )
        let value = await subject.getFeatureFlag(.testFeatureFlag, defaultValue: "fallback", forceRefresh: false)
        #expect(value == "fallback")
    }

    /// `getDebugFeatureFlags(_:)` returns the debug override value when a flag has been overridden
    @Test
    func getDebugFeatureFlags() async throws {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: ["test-feature-flag": .bool(true)],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0",
            ),
        )
        appSettingsStore.overrideDebugFeatureFlag(name: "test-feature-flag", value: false)
        let flags = await subject.getDebugFeatureFlags(FeatureFlag.allCases)
        let flag = try #require(flags.first { $0.feature.rawValue == "test-feature-flag" })
        #expect(!flag.isEnabled)
    }

    // MARK: Tests - Other

    /// `toggleDebugFeatureFlag(name:newValue:)` correctly changes the value of the flag given.
    @Test
    func toggleDebugFeatureFlag() async throws {
        await subject.toggleDebugFeatureFlag(
            name: FeatureFlag.testFeatureFlag.rawValue,
            newValue: true,
        )
        let flags = await subject.getDebugFeatureFlags(FeatureFlag.allCases)
        #expect(appSettingsStore.overrideDebugFeatureFlagCalled)
        let flag = try #require(flags.first { $0.feature == .testFeatureFlag })
        #expect(flag.isEnabled)
    }

    /// `refreshDebugFeatureFlags(_:)` resets the flags to the original state before overriding.
    @Test
    func refreshDebugFeatureFlags() async throws {
        let flags = await subject.refreshDebugFeatureFlags(FeatureFlag.allCases)
        #expect(appSettingsStore.overrideDebugFeatureFlagCalled)
        let flag = try #require(flags.first { $0.feature == .testFeatureFlag })
        #expect(!flag.isEnabled)
    }

    // MARK: Tests - Server communication cookie

    /// `clearServerCommunicationCookieValue(hostname:)` delegates to the state service with the correct hostname.
    @Test
    func clearServerCommunicationCookieValue() async throws {
        try await subject.clearServerCommunicationCookieValue(hostname: "example.com")

        #expect(stateService.clearServerCommCookieValueHostname == "example.com")
    }

    // MARK: Private

    /// Asserts the config publisher is publishing the right values.
    /// - Parameters:
    ///   - isPreAuth: The expected value of `isPreAuth`
    ///   - userId: The expected value of `userId`
    ///   - gitHash: The expected value of `gitHash`
    private func assertConfigPublisherWith(
        isPreAuth: Bool,
        userId: String?,
        gitHash: String?,
        sourceLocation: SourceLocation = #_sourceLocation,
    ) async throws {
        var publisher = await subject.configPublisher().makeAsyncIterator()
        let result = await publisher.next()
        let wrapped = try #require(result, sourceLocation: sourceLocation)
        let metaConfig = try #require(wrapped, sourceLocation: sourceLocation)
        #expect(metaConfig.isPreAuth == isPreAuth, sourceLocation: sourceLocation)
        #expect(metaConfig.userId == userId, sourceLocation: sourceLocation)
        #expect(metaConfig.serverConfig?.gitHash == gitHash, sourceLocation: sourceLocation)
    }
} // swiftlint:disable:this file_length
