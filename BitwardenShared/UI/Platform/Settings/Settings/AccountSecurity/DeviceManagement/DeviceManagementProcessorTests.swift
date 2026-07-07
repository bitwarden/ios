import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceManagementProcessorTests

class DeviceManagementProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authService: MockAuthService!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var deviceAPIService: MockDeviceAPIService!
    var errorReporter: MockErrorReporter!
    var timeProvider: MockTimeProvider!
    var subject: DeviceManagementProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authService = MockAuthService()
        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        deviceAPIService = MockDeviceAPIService()
        errorReporter = MockErrorReporter()
        timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1_718_000_000)))

        subject = DeviceManagementProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authService: authService,
                deviceAPIService: deviceAPIService,
                errorReporter: errorReporter,
                timeProvider: timeProvider,
            ),
            state: DeviceManagementState(),
        )
    }

    override func tearDown() {
        super.tearDown()

        authService = nil
        coordinator = nil
        deviceAPIService = nil
        errorReporter = nil
        timeProvider = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(.loadData)` loads devices and marks the current session correctly.
    @MainActor
    func test_perform_loadData_success() async throws {
        let currentDevice = DeviceResponse.fixture(id: "device-id-1")
        let otherDevice = DeviceResponse.fixture(id: "device-id-2", isTrusted: false)
        deviceAPIService.getDevicesReturnValue = [currentDevice, otherDevice]
        deviceAPIService.getCurrentDeviceReturnValue = currentDevice
        authService.getPendingLoginRequestResult = .success([])

        await subject.perform(.loadData)

        let items = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items.first(where: { $0.id == "device-id-1" })?.isCurrentSession == true)
        XCTAssertFalse(items.first(where: { $0.id == "device-id-2" })?.isCurrentSession == true)
    }

    /// `perform(.loadData)` sorts devices: current session first, then pending requests, then by activity.
    @MainActor
    func test_perform_loadData_sorting() async throws {
        let currentDevice = DeviceResponse.fixture(
            id: "current",
            lastActivityDate: Date(timeIntervalSince1970: 1_717_900_000),
        )
        let pendingDevice = DeviceResponse.fixture(
            id: "pending",
            isTrusted: false,
            lastActivityDate: Date(timeIntervalSince1970: 1_717_800_000),
            type: .chromeExtension,
        )
        let oldDevice = DeviceResponse.fixture(
            id: "old",
            isTrusted: false,
            lastActivityDate: Date(timeIntervalSince1970: 1_600_000_000),
            type: .macOsDesktop,
        )
        let pendingRequest = LoginRequest.fixture(requestDeviceType: "Chrome")

        deviceAPIService.getDevicesReturnValue = [oldDevice, pendingDevice, currentDevice]
        deviceAPIService.getCurrentDeviceReturnValue = currentDevice
        authService.getPendingLoginRequestResult = .success([pendingRequest])

        await subject.perform(.loadData)

        let items = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].id, "current") // current session first
        XCTAssertEqual(items[1].id, "pending") // pending request second
        XCTAssertEqual(items[2].id, "old") // oldest last
    }

    /// `perform(.loadData)` assigns the most recent pending request when multiple exist for the same platform.
    @MainActor
    func test_perform_loadData_matchesMostRecentPendingRequest() async throws {
        let chromeDevice = DeviceResponse.fixture(id: "chrome", type: .chromeExtension)
        let currentDevice = DeviceResponse.fixture(id: "current")
        let olderRequest = LoginRequest.fixture(
            creationDate: Date(timeIntervalSince1970: 1_000_000),
            id: "older",
            requestDeviceType: "Chrome",
        )
        let newerRequest = LoginRequest.fixture(
            creationDate: Date(timeIntervalSince1970: 2_000_000),
            id: "newer",
            requestDeviceType: "Chrome",
        )

        deviceAPIService.getDevicesReturnValue = [chromeDevice, currentDevice]
        deviceAPIService.getCurrentDeviceReturnValue = currentDevice
        authService.getPendingLoginRequestResult = .success([olderRequest, newerRequest])

        await subject.perform(.loadData)

        let items = try XCTUnwrap(subject.state.loadingState.data)
        let chromeItem = try XCTUnwrap(items.first(where: { $0.id == "chrome" }))
        XCTAssertEqual(chromeItem.pendingRequest?.id, "newer")
    }

    /// `perform(.loadData)` sets loading state to empty and reports the error on failure.
    @MainActor
    func test_perform_loadData_error() async {
        deviceAPIService.getDevicesThrowableError = BitwardenTestError.example
        deviceAPIService.getCurrentDeviceThrowableError = BitwardenTestError.example
        authService.getPendingLoginRequestResult = .success([])

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.loadingState, .data([]))
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `receive(.deviceTapped)` navigates to the login request when the device has a pending request.
    @MainActor
    func test_receive_deviceTapped_withPendingRequest() {
        let request = LoginRequest.fixture()
        var device = DeviceListItem.fixture()
        device.pendingRequest = request

        subject.receive(.deviceTapped(device))

        XCTAssertEqual(coordinator.routes.last, .loginRequest(request))
        XCTAssertNotNil(coordinator.contexts.last as? DeviceManagementProcessor)
    }

    /// `receive(.deviceTapped)` does nothing when the device has no pending request.
    @MainActor
    func test_receive_deviceTapped_noPendingRequest() {
        subject.receive(.deviceTapped(.fixture()))

        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `receive(.dismiss)` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(.toastShown)` updates and clears the toast state.
    @MainActor
    func test_receive_toastShown() {
        subject.receive(.toastShown(Toast(title: "test")))
        XCTAssertEqual(subject.state.toast, Toast(title: "test"))

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `loginRequestAnswered(approved: true)` shows the approved toast and reloads.
    @MainActor
    func test_loginRequestAnswered_approved() {
        deviceAPIService.getDevicesReturnValue = []
        deviceAPIService.getCurrentDeviceReturnValue = .fixture()
        authService.getPendingLoginRequestResult = .success([])

        let task = Task { subject.loginRequestAnswered(approved: true) }
        waitFor(deviceAPIService.getDevicesCalled)
        task.cancel()

        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.loginApproved))
    }

    /// `loginRequestAnswered(approved: false)` shows the denied toast and reloads.
    @MainActor
    func test_loginRequestAnswered_denied() {
        deviceAPIService.getDevicesReturnValue = []
        deviceAPIService.getCurrentDeviceReturnValue = .fixture()
        authService.getPendingLoginRequestResult = .success([])

        let task = Task { subject.loginRequestAnswered(approved: false) }
        waitFor(deviceAPIService.getDevicesCalled)
        task.cancel()

        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.logInDenied))
    }
}
