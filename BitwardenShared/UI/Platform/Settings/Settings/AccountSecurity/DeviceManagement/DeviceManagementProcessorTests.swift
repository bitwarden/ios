import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceManagementProcessorTests

@MainActor
struct DeviceManagementProcessorTests {
    // MARK: Properties

    let authService: MockAuthService
    let coordinator: MockCoordinator<SettingsRoute, SettingsEvent>
    let deviceAPIService: MockDeviceAPIService
    let errorReporter: MockErrorReporter
    let timeProvider: MockTimeProvider
    let subject: DeviceManagementProcessor

    // MARK: Initialization

    init() {
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

    // MARK: Tests

    /// `perform(_:)` loads devices and marks the current session correctly.
    @Test
    func perform_loadData_success() async throws {
        let currentDevice = DeviceResponse.fixture(id: "device-id-1")
        let otherDevice = DeviceResponse.fixture(id: "device-id-2", isTrusted: false)
        deviceAPIService.getDevicesReturnValue = [currentDevice, otherDevice]
        deviceAPIService.getCurrentDeviceReturnValue = currentDevice
        authService.getPendingLoginRequestResult = .success([])

        await subject.perform(.loadData)

        let items = try #require(subject.state.loadingState.data)
        #expect(items.count == 2)
        #expect(items.first(where: { $0.id == "device-id-1" })?.isCurrentSession == true)
        #expect(items.first(where: { $0.id == "device-id-2" })?.isCurrentSession == false)
    }

    /// `perform(_:)` sorts devices: current session first, then pending requests, then by activity.
    @Test
    func perform_loadData_sorting() async throws {
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

        let items = try #require(subject.state.loadingState.data)
        #expect(items.count == 3)
        #expect(items[0].id == "current") // current session first
        #expect(items[1].id == "pending") // pending request second
        #expect(items[2].id == "old") // oldest last
    }

    /// `perform(_:)` assigns the most recent pending request when multiple exist for the same platform.
    @Test
    func perform_loadData_matchesMostRecentPendingRequest() async throws {
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

        let items = try #require(subject.state.loadingState.data)
        let chromeItem = try #require(items.first(where: { $0.id == "chrome" }))
        #expect(chromeItem.pendingRequest?.id == "newer")
    }

    /// `perform(_:)` sets loading state to empty and reports the error on failure.
    @Test
    func perform_loadData_error() async {
        deviceAPIService.getDevicesThrowableError = BitwardenTestError.example
        deviceAPIService.getCurrentDeviceThrowableError = BitwardenTestError.example
        authService.getPendingLoginRequestResult = .success([])

        await subject.perform(.loadData)

        #expect(subject.state.loadingState == .data([]))
        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `receive(_:)` navigates to the login request when the device has a pending request.
    @Test
    func receive_deviceTapped_withPendingRequest() {
        let request = LoginRequest.fixture()
        var device = DeviceListItem.fixture()
        device.pendingRequest = request

        subject.receive(.deviceTapped(device))

        #expect(coordinator.routes.last == .loginRequest(request))
        #expect(coordinator.contexts.last is DeviceManagementProcessor)
    }

    /// `receive(_:)` does nothing when the device has no pending request.
    @Test
    func receive_deviceTapped_noPendingRequest() {
        subject.receive(.deviceTapped(.fixture()))

        #expect(coordinator.routes.isEmpty)
    }

    /// `receive(_:)` dismisses the view.
    @Test
    func receive_dismiss() {
        subject.receive(.dismiss)

        #expect(coordinator.routes.last == .dismiss)
    }

    /// `receive(_:)` updates and clears the toast state.
    @Test
    func receive_toastShown() {
        subject.receive(.toastShown(Toast(title: "test")))
        #expect(subject.state.toast == Toast(title: "test"))

        subject.receive(.toastShown(nil))
        #expect(subject.state.toast == nil)
    }

    /// `loginRequestAnswered(approved:)` shows the approved toast and triggers a reload.
    @Test
    func loginRequestAnswered_approved() async throws {
        deviceAPIService.getDevicesReturnValue = []
        deviceAPIService.getCurrentDeviceReturnValue = .fixture()
        authService.getPendingLoginRequestResult = .success([])

        subject.loginRequestAnswered(approved: true)

        #expect(subject.state.toast == Toast(title: Localizations.loginApproved))
        try await waitForAsync { deviceAPIService.getDevicesCalled }
    }

    /// `loginRequestAnswered(approved:)` shows the denied toast and triggers a reload.
    @Test
    func loginRequestAnswered_denied() async throws {
        deviceAPIService.getDevicesReturnValue = []
        deviceAPIService.getCurrentDeviceReturnValue = .fixture()
        authService.getPendingLoginRequestResult = .success([])

        subject.loginRequestAnswered(approved: false)

        #expect(subject.state.toast == Toast(title: Localizations.logInDenied))
        try await waitForAsync { deviceAPIService.getDevicesCalled }
    }
}
