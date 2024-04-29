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
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `getConfig(:)` gets the configuration from the server if `forceRefresh` is true
    func test_getConfig_local_forceRefresh() async {
        stateService.config = ServerConfig(
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
        stateService.config = ServerConfig(
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
        stateService.config = ServerConfig(
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
        stateService.config = nil
        client.result = .httpSuccess(testData: .validServerConfig)
        let response = await subject.getConfig(forceRefresh: false)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(response?.gitHash, "75238191")
    }
}
