import XCTest

@testable import BitwardenShared

final class ConfigServiceTests: BitwardenTestCase {
    // MARK: Properties

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

        client = MockHTTPClient()
        configApiService = APIService(client: client)
        errorReporter = MockErrorReporter()
        now = Date(year: 2024, month: 2, day: 14, hour: 8, minute: 0, second: 0)
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(now))
        subject = DefaultConfigService(
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

        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `getConfig(:)` gets the configuration from the server if `forceRefresh` is true
    func test_getConfig_local_forceRefresh() async {
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
        let response = await subject.getConfig(forceRefresh: true)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(response?.gitHash, "75238191")
    }

    /// `getConfig(:)` uses the local configuration if it is expired
    func test_getConfig_local_expired() async {
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
        let response = await subject.getConfig(forceRefresh: false)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(response?.gitHash, "75238191")
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
        let response = await subject.getConfig(forceRefresh: false)
        XCTAssertEqual(client.requests.count, 0)
        XCTAssertEqual(response?.gitHash, "75238192")
    }

    /// `getConfig(:)` gets the configuration from the server if there is no local configuration
    func test_getConfig_noLocal() async {
        client.result = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: false)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(response?.gitHash, "75238191")
        XCTAssertEqual(response?.featureStates[.testRemoteFeatureFlag], .bool(true))
    }

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
}
