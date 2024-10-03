import XCTest

@testable import BitwardenShared

final class ConfigServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var client: MockHTTPClient!
    var configApiService: APIService!
    var errorReporter: MockErrorReporter!
    var now: Date!
    var stateService: MockStateService!
    var subject: DefaultConfigService!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        client = MockHTTPClient()
        configApiService = APIService(client: client)
        errorReporter = MockErrorReporter()
        now = Date(year: 2024, month: 2, day: 14, hour: 8, minute: 0, second: 0)
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(now))
        subject = DefaultConfigService(
            appSettingsStore: appSettingsStore,
            configApiService: configApiService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        stateService.activeAccount = account
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        client = nil
        configApiService = nil
        errorReporter = nil
        stateService = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests - getConfig remote interactions

    /// `getConfig(:)` gets the configuration from the server if `forceRefresh` is true
    func test_getConfig_local_forceRefresh() async throws {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        client.result = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: false)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(response?.gitHash, "75238191")

        try await assertConfigPublisherWith(isPreAuth: false, userId: "1", gitHash: "75238191")
    }

    /// `getConfig(:)` gets the local config when server throws if `forceRefresh` is true
    func test_getConfig_local_forceRefreshServerCallThrowing() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        client.result = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: false)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(response?.gitHash, "75238192")
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `getConfig(:)` uses the local configuration if it is expired
    /// but updates the local config when the http request finishes.
    func test_getConfig_local_expired() async throws {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 10, hour: 8, minute: 0, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        client.result = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
        XCTAssertEqual(response?.gitHash, "75238192")

        try await waitForAsync {
            self.client.requests.count == 1
        }

        XCTAssertEqual(stateService.serverConfig["1"]?.gitHash, "75238191")

        try await assertConfigPublisherWith(isPreAuth: false, userId: "1", gitHash: "75238191")
    }

    /// `getConfig(:)` uses the local configuration if it is expired
    /// but updates the local config when the http request finishes.
    func test_getConfig_local_expiredAndServerCallThrowing() async throws {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 10, hour: 8, minute: 0, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        client.result = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
        XCTAssertEqual(response?.gitHash, "75238192")

        try await waitForAsync {
            self.client.requests.count == 1
        }

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `getConfig(:)` uses the local configuration if it's not expired
    func test_getConfig_local_notExpired() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(response?.gitHash, "75238192")
    }

    /// `getConfig(:)` gets the configuration from the server if there is no local configuration
    ///  but in background returning nil to the caller as is the current available local config.
    func test_getConfig_noLocal() async throws {
        client.result = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
        XCTAssertNil(response)

        try await waitForAsync {
            self.client.requests.count == 1
        }

        XCTAssertEqual(stateService.serverConfig["1"]?.gitHash, "75238191")
        XCTAssertEqual(stateService.serverConfig["1"]?.featureStates[.testRemoteFeatureFlag], .bool(true))
    }

    /// `getConfig(:)` gets the configuration from the pre authenticated server config if `forceRefresh` is true,
    /// there is no local config and there's a pre authenticated server config.
    /// It also updates the local config with the pre authenticated server config.
    func test_getConfig_forceRefreshServerCallThrowingWithPreAuthConfig() async {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        client.result = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: false)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(response?.gitHash, "75238192")
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(stateService.serverConfig["1"]?.gitHash, "75238192")
    }

    /// `getConfig(:)` returns `nil` if `forceRefresh` is true,
    /// there is no local config nor a pre authenticated server config.
    func test_getConfig_forceRefreshServerCallThrowingWithoutPreAuthConfig() async {
        client.result = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: false)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(response)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertNil(stateService.serverConfig["1"])
        XCTAssertNil(stateService.preAuthServerConfig)
    }

    // MARK: Tests - getConfig pre-auth

    /// `getConfig(:)` gets the configuration from the server if `forceRefresh` is true
    /// and the user has not been authenticated.
    func test_getConfig_local_forceRefreshPreAuth() async throws {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        client.result = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: true, isPreAuth: true)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(response?.gitHash, "75238191")
        XCTAssertEqual(stateService.preAuthServerConfig?.gitHash, "75238191")

        try await assertConfigPublisherWith(isPreAuth: true, userId: "1", gitHash: "75238191")
    }

    /// `getConfig(:)` uses the local configuration if it is expired
    /// and the user has not been authenticated
    /// but updates the local config when the http request finishes.
    func test_getConfig_local_expiredPreAuth() async throws {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 10, hour: 8, minute: 0, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        client.result = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: true)
        XCTAssertEqual(response?.gitHash, "75238192")

        try await waitForAsync {
            self.client.requests.count == 1
        }

        XCTAssertEqual(stateService.preAuthServerConfig?.gitHash, "75238191")

        try await assertConfigPublisherWith(isPreAuth: true, userId: "1", gitHash: "75238191")
    }

    /// `getConfig(:)` uses the local configuration if it is expired, server throws
    /// and the user has not been authenticated
    /// but updates the local config when the http request finishes.
    func test_getConfig_local_expiredAndServerCallThrowingPreAuth() async throws {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 10, hour: 8, minute: 0, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        client.result = .failure(BitwardenTestError.example)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: true)
        XCTAssertEqual(response?.gitHash, "75238192")

        try await waitForAsync {
            self.client.requests.count == 1
        }

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `getConfig(:)` uses the local configuration if it's not expired
    /// and the user has not been authenticated
    func test_getConfig_local_notExpiredPreAuth() async {
        stateService.preAuthServerConfig = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238192",
                server: nil,
                version: "2024.4.0"
            )
        )
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: true)
        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(response?.gitHash, "75238192")
        XCTAssertEqual(stateService.preAuthServerConfig?.gitHash, "75238192")
    }

    /// `getConfig(:)` gets the configuration from the server if there is no local configuration
    /// and the user has not been authenticated
    /// but in background returning nil to the caller as is the current available local config.
    func test_getConfig_noLocalPreAuth() async throws {
        client.result = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: false, isPreAuth: true)
        XCTAssertNil(response)

        try await waitForAsync {
            self.client.requests.count == 1
        }

        XCTAssertEqual(stateService.preAuthServerConfig?.gitHash, "75238191")
        XCTAssertEqual(stateService.preAuthServerConfig?.featureStates[.testRemoteFeatureFlag], .bool(true))
    }

    // MARK: Tests - getConfig initial values

    /// `getFeatureFlag(:)` returns the initial value for local-only booleans if it is configured.
    func test_getFeatureFlag_initialValue_localBool() async {
        let value = await subject.getFeatureFlag(
            .testLocalInitialBoolFlag,
            defaultValue: false,
            forceRefresh: false
        )
        XCTAssertTrue(value)
    }

    /// `getFeatureFlag(:)` returns the initial value for local-only integers if it is configured.
    func test_getFeatureFlag_initialValue_localInt() async {
        let value = await subject.getFeatureFlag(
            .testLocalInitialIntFlag,
            defaultValue: 10,
            forceRefresh: false
        )
        XCTAssertEqual(value, 42)
    }

    /// `getFeatureFlag(:)` returns the initial value for local-only strings if it is configured.
    func test_getFeatureFlag_initialValue_localString() async {
        let value = await subject.getFeatureFlag(
            .testLocalInitialStringFlag,
            defaultValue: "Default",
            forceRefresh: false
        )
        XCTAssertEqual(value, "Test String")
    }

    /// `getFeatureFlag(:)` returns the initial value for remote-configured booleans if it is configured.
    func test_getFeatureFlag_initialValue_remoteBool() async {
        let value = await subject.getFeatureFlag(
            .testRemoteInitialBoolFlag,
            defaultValue: false,
            forceRefresh: false
        )
        XCTAssertTrue(value)
    }

    /// `getFeatureFlag(:)` returns the initial value for remote-configured integers if it is configured.
    func test_getFeatureFlag_initialValue_remoteInt() async {
        let value = await subject.getFeatureFlag(
            .testRemoteInitialIntFlag,
            defaultValue: 10,
            forceRefresh: false
        )
        XCTAssertEqual(value, 42)
    }

    /// `getFeatureFlag(:)` returns the initial value for remote-configured integers if it is configured.
    func test_getFeatureFlag_initialValue_remoteString() async {
        let value = await subject.getFeatureFlag(
            .testRemoteInitialStringFlag,
            defaultValue: "Default",
            forceRefresh: false
        )
        XCTAssertEqual(value, "Test String")
    }

    // MARK: Tests - getFeatureFlag

    /// `getFeatureFlag(:)` can return a boolean if it's in the configuration
    func test_getFeatureFlag_bool_exists() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: ["test-remote-feature-flag": .bool(true)],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        let value = await subject.getFeatureFlag(.testRemoteFeatureFlag, defaultValue: false, forceRefresh: false)
        XCTAssertTrue(value)
    }

    /// `getFeatureFlag(:)` returns the default value for booleans
    func test_getFeatureFlag_bool_fallback() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        let value = await subject.getFeatureFlag(.testRemoteFeatureFlag, defaultValue: true, forceRefresh: false)
        XCTAssertTrue(value)
    }

    /// `getFeatureFlag(:)` returns the default value if the feature is not remotely configurable for booleans
    func test_getFeatureFlag_bool_notRemotelyConfigured() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: ["test-remote-feature-flag": .bool(true)],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        let value = await subject.getFeatureFlag(.testLocalFeatureFlag, defaultValue: false, forceRefresh: false)
        XCTAssertFalse(value)
    }

    /// `getFeatureFlag(:)` can return an integer if it's in the configuration
    func test_getFeatureFlag_int_exists() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: ["test-remote-feature-flag": .int(42)],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        let value = await subject.getFeatureFlag(.testRemoteFeatureFlag, defaultValue: 30, forceRefresh: false)
        XCTAssertEqual(value, 42)
    }

    /// `getFeatureFlag(:)` returns the default value for integers
    func test_getFeatureFlag_int_fallback() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        let value = await subject.getFeatureFlag(.testRemoteFeatureFlag, defaultValue: 30, forceRefresh: false)
        XCTAssertEqual(value, 30)
    }

    /// `getFeatureFlag(:)` returns the default value if the feature is not remotely configurable for integers
    func test_getFeatureFlag_int_notRemotelyConfigured() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: ["test-remote-feature-flag": .int(42)],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        let value = await subject.getFeatureFlag(.testLocalFeatureFlag, defaultValue: 30, forceRefresh: false)
        XCTAssertEqual(value, 30)
    }

    /// `getFeatureFlag(:)` can return a string if it's in the configuration
    func test_getFeatureFlag_string_exists() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: ["test-remote-feature-flag": .string("exists")],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        let value = await subject.getFeatureFlag(.testRemoteFeatureFlag, defaultValue: "fallback", forceRefresh: false)
        XCTAssertEqual(value, "exists")
    }

    /// `getFeatureFlag(:)` returns the default value for strings
    func test_getFeatureFlag_string_fallback() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        let value = await subject.getFeatureFlag(.testRemoteFeatureFlag, defaultValue: "fallback", forceRefresh: false)
        XCTAssertEqual(value, "fallback")
    }

    /// `getFeatureFlag(:)` returns the default value if the feature is not remotely configurable for strings
    func test_getFeatureFlag_string_notRemotelyConfigured() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: ["test-remote-feature-flag": .string("exists")],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        let value = await subject.getFeatureFlag(.testLocalFeatureFlag, defaultValue: "fallback", forceRefresh: false)
        XCTAssertEqual(value, "fallback")
    }

    /// `getDebugFeatureFlags(:)` returns the default value if the feature is not remotely configurable for strings
    func test_getDebugFeatureFlags() async {
        stateService.serverConfig["1"] = ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: ["email-verification": .bool(true)],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        )
        appSettingsStore.overrideDebugFeatureFlag(name: "email-verification", value: false)
        let flags = await subject.getDebugFeatureFlags()
        let emailVerificationFlag = try? XCTUnwrap(flags.first { $0.feature.rawValue == "email-verification" })
        XCTAssertFalse(emailVerificationFlag?.isEnabled ?? true)
    }

    // MARK: Tests - Other

    /// `toggleDebugFeatureFlag` will correctly change the value of the flag given.
    func test_toggleDebugFeatureFlag() async throws {
        let flags = await subject.toggleDebugFeatureFlag(
            name: FeatureFlag.emailVerification.rawValue,
            newValue: true
        )
        XCTAssertTrue(appSettingsStore.overrideDebugFeatureFlagCalled)
        let flag = try XCTUnwrap(flags.first { $0.feature == .emailVerification })
        XCTAssertTrue(flag.isEnabled)
    }

    /// `refreshDebugFeatureFlags` will reset the flags to the original state before overriding.
    func test_refreshDebugFeatureFlags() async throws {
        let flags = await subject.refreshDebugFeatureFlags()
        XCTAssertTrue(appSettingsStore.overrideDebugFeatureFlagCalled)
        let flag = try XCTUnwrap(flags.first { $0.feature == .emailVerification })
        XCTAssertFalse(flag.isEnabled)
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
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        var publisher = try await subject.configPublisher().makeAsyncIterator()
        let result = try await publisher.next()
        let metaConfig = try XCTUnwrap(XCTUnwrap(result))
        XCTAssertEqual(metaConfig.isPreAuth, isPreAuth, file: file, line: line)
        XCTAssertEqual(metaConfig.userId, userId, file: file, line: line)
        XCTAssertEqual(metaConfig.serverConfig?.gitHash, gitHash, file: file, line: line)
    }
} // swiftlint:disable:this file_length
