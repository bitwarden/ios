import XCTest

@testable import AuthenticatorShared

final class ConfigServiceTests: AuthenticatorTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var errorReporter: MockErrorReporter!
    var now: Date!
    var stateService: MockStateService!
    var subject: DefaultConfigService!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        errorReporter = MockErrorReporter()
        now = Date(year: 2024, month: 2, day: 14, hour: 8, minute: 0, second: 0)
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(now))
        subject = DefaultConfigService(
            appSettingsStore: appSettingsStore,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        errorReporter = nil
        stateService = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests - getConfig remote interactions

    // TODO: BWA-92 to backfill these tests, or obviate it by pulling the ConfigService into a shared library.

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

    // MARK: Tests - Other

    /// `toggleDebugFeatureFlag` will correctly change the value of the flag given.
    func test_toggleDebugFeatureFlag() async throws {
        let flags = await subject.toggleDebugFeatureFlag(
            name: FeatureFlag.enablePasswordManagerSync.rawValue,
            newValue: true
        )
        XCTAssertTrue(appSettingsStore.overrideDebugFeatureFlagCalled)
        let flag = try XCTUnwrap(flags.first { $0.feature == .enablePasswordManagerSync })
        XCTAssertTrue(flag.isEnabled)
    }

    /// `refreshDebugFeatureFlags` will reset the flags to the original state before overriding.
    func test_refreshDebugFeatureFlags() async throws {
        let flags = await subject.refreshDebugFeatureFlags()
        XCTAssertTrue(appSettingsStore.overrideDebugFeatureFlagCalled)
        let flag = try XCTUnwrap(flags.first { $0.feature == .enablePasswordManagerSync })
        XCTAssertFalse(flag.isEnabled)
    }
}
