import XCTest

@testable import BitwardenShared

class NotificationServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authService: MockAuthService!
    var client: MockHTTPClient!
    var delegate: MockNotificationServiceDelegate!
    var errorReporter: MockErrorReporter!
    var notificationAPIService: NotificationAPIService!
    var stateService: MockStateService!
    var subject: DefaultNotificationService!
    var syncService: MockSyncService!

    // MARK: Set Up & Tear Down

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        authService = MockAuthService()
        client = MockHTTPClient()
        delegate = MockNotificationServiceDelegate()
        errorReporter = MockErrorReporter()
        notificationAPIService = APIService(client: client)
        stateService = MockStateService()
        syncService = MockSyncService()

        subject = DefaultNotificationService(
            appIdService: AppIdService(appSettingStore: appSettingsStore),
            authService: authService,
            errorReporter: errorReporter,
            notificationAPIService: notificationAPIService,
            stateService: stateService,
            syncService: syncService
        )
        subject.setDelegate(delegate)
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        authService = nil
        client = nil
        delegate = nil
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

    /// `messageReceived(_:notificationDismissed:notificationTapped:)` tells
    /// the delegate to show the switch account alert if it's a login request for a non-active account.
    func test_messageReceived_loginRequest_differentAccount() async throws {
        // Set up the mock data.
        stateService.setIsAuthenticated()
        stateService.accounts = [.fixture(), .fixture(profile: .fixture(userId: "differentUser"))]
        appSettingsStore.appId = "10"
        stateService.approveLoginRequestsByUserId["1"] = true
        authService.getPendingLoginRequestResult = .success([.fixture()])
        let loginRequestNotification = LoginRequestNotification(id: "requestId", userId: "differentUser")
        let notificationData = try JSONEncoder().encode(loginRequestNotification)
        let message: [AnyHashable: Any] = [
            "aps": [
                "data": [
                    "type": NotificationType.authRequest.rawValue,
                    "payload": String(data: notificationData, encoding: .utf8) ?? "",
                ],
            ],
        ]

        // Test.
        await subject.messageReceived(message, notificationDismissed: nil, notificationTapped: nil)

        // Confirm the results.
        XCTAssertEqual(stateService.loginRequest, loginRequestNotification)
        XCTAssertEqual(delegate.switchAccountsAccount, .fixture(profile: .fixture(userId: "differentUser")))
        XCTAssertEqual(delegate.switchAccountsLoginRequest, .fixture())
        XCTAssertEqual(delegate.switchAccountsShowAlert, true)
    }

    /// `messageReceived(_:notificationDismissed:notificationTapped:)` tells
    /// the delegate to show the login request if it's a login request for the active account.
    func test_messageReceived_loginRequest_sameAccount() async throws {
        // Set up the mock data.
        stateService.setIsAuthenticated()
        stateService.accounts = [.fixture()]
        appSettingsStore.appId = "10"
        stateService.approveLoginRequestsByUserId["1"] = true
        authService.getPendingLoginRequestResult = .success([.fixture()])
        let loginRequestNotification = LoginRequestNotification(id: "requestId", userId: "1")
        let notificationData = try JSONEncoder().encode(loginRequestNotification)
        let message: [AnyHashable: Any] = [
            "aps": [
                "data": [
                    "type": NotificationType.authRequest.rawValue,
                    "payload": String(data: notificationData, encoding: .utf8) ?? "",
                ],
            ],
        ]

        // Test.
        await subject.messageReceived(message, notificationDismissed: nil, notificationTapped: nil)

        // Confirm the results.
        XCTAssertEqual(stateService.loginRequest, loginRequestNotification)
        XCTAssertEqual(delegate.showLoginRequestRequest, .fixture())
    }

    /// `messageReceived(_:notificationDismissed:notificationTapped:)` handles notifications being dismissed.
    func test_messageReceived_notificationDismissed() async throws {
        // Set up the mock data.
        stateService.loginRequest = LoginRequestNotification(id: "1", userId: "2")
        let loginRequest = LoginRequestPushNotification(
            timeoutInMinutes: 15,
            userEmail: "test@email.com"
        )
        let testData = try JSONEncoder().encode(loginRequest)
        let message: [AnyHashable: Any] = [
            "notificationData": String(data: testData, encoding: .utf8) ?? "",
        ]

        // Test.
        await subject.messageReceived(message, notificationDismissed: true, notificationTapped: nil)

        // Confirm the results.
        XCTAssertNil(stateService.loginRequest)
    }

    /// `messageReceived(_:notificationDismissed:notificationTapped:)` handles notifications being tapped.
    func test_messageReceived_notificationTapped() async throws {
        // Set up the mock data.
        stateService.accounts = [.fixture()]
        stateService.activeAccount = .fixtureAccountLogin()
        stateService.loginRequest = LoginRequestNotification(id: "requestId", userId: "1")
        authService.getPendingLoginRequestResult = .success([.fixture(id: "requestId")])
        let loginRequest = LoginRequestPushNotification(
            timeoutInMinutes: 15,
            userEmail: Account.fixture().profile.email
        )
        let testData = try JSONEncoder().encode(loginRequest)
        let message: [AnyHashable: Any] = [
            "notificationData": String(data: testData, encoding: .utf8) ?? "",
        ]

        // Test.
        await subject.messageReceived(message, notificationDismissed: nil, notificationTapped: true)

        // Confirm the results.
        XCTAssertEqual(delegate.switchAccountsAccount, .fixture())
        XCTAssertEqual(delegate.switchAccountsLoginRequest, .fixture(id: "requestId"))
        XCTAssertEqual(delegate.switchAccountsShowAlert, false)
    }

    /// `messageReceived(_:notificationDismissed:notificationTapped:)` handles errors.
    func test_messageReceived_notificationTapped_error() async throws {
        // Set up the mock data.
        stateService.accounts = [.fixture()]
        stateService.activeAccount = .fixtureAccountLogin()
        stateService.loginRequest = LoginRequestNotification(id: "requestId", userId: "1")
        authService.getPendingLoginRequestResult = .failure(BitwardenTestError.example)
        let loginRequest = LoginRequestPushNotification(
            timeoutInMinutes: 15,
            userEmail: Account.fixture().profile.email
        )
        let testData = try JSONEncoder().encode(loginRequest)
        let message: [AnyHashable: Any] = [
            "notificationData": String(data: testData, encoding: .utf8) ?? "",
        ]

        // Test.
        await subject.messageReceived(message, notificationDismissed: nil, notificationTapped: true)

        // Confirm the results.
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }
}

// MARK: - MockNotificationServiceDelegate

class MockNotificationServiceDelegate: NotificationServiceDelegate {
    var showLoginRequestRequest: LoginRequest?

    var switchAccountsAccount: Account?
    var switchAccountsLoginRequest: LoginRequest?
    var switchAccountsShowAlert: Bool?

    func showLoginRequest(_ loginRequest: LoginRequest) {
        showLoginRequestRequest = loginRequest
    }

    func switchAccounts(to account: Account, for loginRequest: LoginRequest, showAlert: Bool) {
        switchAccountsAccount = account
        switchAccountsLoginRequest = loginRequest
        switchAccountsShowAlert = showAlert
    }
}
