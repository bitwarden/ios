import XCTest

@testable import BitwardenShared

class NotificationServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authAPIService: AuthAPIService!
    var client: MockHTTPClient!
    var errorReporter: MockErrorReporter!
    var notificationAPIService: NotificationAPIService!
    var stateService: MockStateService!
    var subject: DefaultNotificationService!
    var syncService: MockSyncService!

    // MARK: Set Up & Tear Down

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        client = MockHTTPClient()
        authAPIService = APIService(client: client)
        errorReporter = MockErrorReporter()
        notificationAPIService = APIService(client: client)
        stateService = MockStateService()
        syncService = MockSyncService()

        subject = DefaultNotificationService(
            appIdService: AppIdService(appSettingStore: appSettingsStore),
            authAPIService: authAPIService,
            errorReporter: errorReporter,
            notificationAPIService: notificationAPIService,
            stateService: stateService,
            syncService: syncService
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        authAPIService = nil
        client = nil
        errorReporter = nil
        notificationAPIService = nil
        stateService = nil
        subject = nil
        syncService = nil
    }

    // MARK: Tests

    /// `didRegister(withToken:)` decodes and saves the token.
    func test_didRegister() async throws {
        // Set up the mock data.
        let tokenData = try XCTUnwrap("Hi there :3".data(using: .utf8))
        stateService.setIsAuthenticated()
        appSettingsStore.appId = "10"
        client.result = .httpSuccess(testData: .emptyResponse)

        // Test.
        await subject.didRegister(withToken: tokenData)

        // Confirm the results.
        XCTAssertEqual(client.requests.last?.url.absoluteString, "https://example.com/api/devices/identifier/10/token")
        XCTAssertNotNil(stateService.notificationsLastRegistrationDates["1"])
    }

    /// `didRegister(withToken:)` handles any errors.
    func test_didRegister_error() async throws {
        // Set up the mock data.
        let tokenData = try XCTUnwrap("Hi there :3".data(using: .utf8))
        stateService.setIsAuthenticated()
        appSettingsStore.appId = "10"
        client.result = .httpFailure(BitwardenTestError.example)

        // Test.
        await subject.didRegister(withToken: tokenData)

        // Confirm the results.
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `messageReceived(_:notificationDismissed:notificationTapped:)` handles any errors.
    func test_messageReceived_errors() async throws {
        // Set up the mock data.
        stateService.setIsAuthenticated()
        appSettingsStore.appId = "10"
        let message: [AnyHashable: Any] = [
            "aps": [
                "data": [
                    "type": "malformed",
                    "payload": "anything",
                ],
            ],
        ]

        // Test.
        await subject.messageReceived(message, notificationDismissed: nil, notificationTapped: nil)

        // Confirm the results.
        XCTAssertFalse(errorReporter.errors.isEmpty)
    }

    /// `messageReceived(_:notificationDismissed:notificationTapped:)` handles messages appropriately.
    func test_messageReceived_fetchSync() async throws {
        // Set up the mock data.
        stateService.setIsAuthenticated()
        appSettingsStore.appId = "10"
        let message: [AnyHashable: Any] = [
            "aps": [
                "data": [
                    "type": NotificationType.syncVault.rawValue,
                    "payload": "anything",
                ],
            ],
        ]

        // Test.
        await subject.messageReceived(message, notificationDismissed: nil, notificationTapped: nil)

        // Confirm the results.
        XCTAssertTrue(syncService.didFetchSync)
    }
}
