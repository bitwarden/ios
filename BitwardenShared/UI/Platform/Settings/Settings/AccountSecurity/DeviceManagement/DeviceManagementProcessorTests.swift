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
        let pendingRequest = LoginRequest.fixture(requestDeviceType: "Chrome")
        let pendingDevice = DeviceResponse.fixture(
            devicePendingAuthRequest: .fixture(creationDate: pendingRequest.creationDate, id: pendingRequest.id),
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

    /// `perform(_:)` matches a device's pending request by the id the server reports directly on
    /// that device, not by a coarse platform-name heuristic.
    @Test
    func perform_loadData_matchesPendingRequestById() async throws {
        let otherRequest = LoginRequest.fixture(id: "other-request", requestDeviceType: "Chrome")
        let matchingRequest = LoginRequest.fixture(id: "matching-request", requestDeviceType: "Chrome")
        let chromeDevice = DeviceResponse.fixture(
            devicePendingAuthRequest: .fixture(creationDate: matchingRequest.creationDate, id: matchingRequest.id),
            id: "chrome",
            type: .chromeExtension,
        )
        let currentDevice = DeviceResponse.fixture(id: "current")

        deviceAPIService.getDevicesReturnValue = [chromeDevice, currentDevice]
        deviceAPIService.getCurrentDeviceReturnValue = currentDevice
        authService.getPendingLoginRequestResult = .success([otherRequest, matchingRequest])

        await subject.perform(.loadData)

        let items = try #require(subject.state.loadingState.data)
        let chromeItem = try #require(items.first(where: { $0.id == "chrome" }))
        #expect(chromeItem.pendingRequest?.id == "matching-request")
    }

    /// `perform(_:)` only flags the device the server marked with a pending auth request, even when
    /// multiple devices share the same platform and multiple valid requests exist for that platform.
    @Test
    func perform_loadData_multipleDevicesSamePlatformOnlyMatchesFlaggedDevice() async throws {
        let flaggedRequest = LoginRequest.fixture(id: "flagged-request", requestDeviceType: "Chrome")
        let otherRequest1 = LoginRequest.fixture(id: "other-request-1", requestDeviceType: "Chrome")
        let otherRequest2 = LoginRequest.fixture(id: "other-request-2", requestDeviceType: "Chrome")

        let flaggedChromeDevice = DeviceResponse.fixture(
            devicePendingAuthRequest: .fixture(creationDate: flaggedRequest.creationDate, id: flaggedRequest.id),
            id: "chrome-1",
            type: .chromeExtension,
        )
        let unflaggedChromeDevice1 = DeviceResponse.fixture(id: "chrome-2", type: .chromeExtension)
        let unflaggedChromeDevice2 = DeviceResponse.fixture(id: "chrome-3", type: .chromeExtension)
        let currentDevice = DeviceResponse.fixture(id: "current")

        deviceAPIService.getDevicesReturnValue = [
            flaggedChromeDevice, unflaggedChromeDevice1, unflaggedChromeDevice2, currentDevice,
        ]
        deviceAPIService.getCurrentDeviceReturnValue = currentDevice
        authService.getPendingLoginRequestResult = .success([flaggedRequest, otherRequest1, otherRequest2])

        await subject.perform(.loadData)

        let items = try #require(subject.state.loadingState.data)
        #expect(items.first(where: { $0.id == "chrome-1" })?.pendingRequest?.id == "flagged-request")
        #expect(items.first(where: { $0.id == "chrome-2" })?.pendingRequest == nil)
        #expect(items.first(where: { $0.id == "chrome-3" })?.pendingRequest == nil)
    }

    /// `perform(_:)` leaves a device unmatched when its pending auth request id isn't present in
    /// the pending login requests list (e.g. it was answered or expired between the two calls).
    @Test
    func perform_loadData_pendingAuthRequestIdWithNoMatchingRequestLeavesUnmatched() async throws {
        let chromeDevice = DeviceResponse.fixture(
            devicePendingAuthRequest: .fixture(id: "missing-request"),
            id: "chrome",
            type: .chromeExtension,
        )
        let currentDevice = DeviceResponse.fixture(id: "current")

        deviceAPIService.getDevicesReturnValue = [chromeDevice, currentDevice]
        deviceAPIService.getCurrentDeviceReturnValue = currentDevice
        authService.getPendingLoginRequestResult = .success([])

        await subject.perform(.loadData)

        let items = try #require(subject.state.loadingState.data)
        #expect(items.allSatisfy { $0.pendingRequest == nil })
    }

    /// `perform(_:)` leaves a device without a pending auth request id unmatched, even when
    /// pending login requests exist for other devices.
    @Test
    func perform_loadData_deviceWithoutPendingAuthRequestIdRemainsUnmatched() async throws {
        let chromeDevice = DeviceResponse.fixture(id: "chrome", type: .chromeExtension)
        let currentDevice = DeviceResponse.fixture(id: "current")
        let request = LoginRequest.fixture(requestDeviceType: "Chrome")

        deviceAPIService.getDevicesReturnValue = [chromeDevice, currentDevice]
        deviceAPIService.getCurrentDeviceReturnValue = currentDevice
        authService.getPendingLoginRequestResult = .success([request])

        await subject.perform(.loadData)

        let items = try #require(subject.state.loadingState.data)
        #expect(items.allSatisfy { $0.pendingRequest == nil })
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
    func receive_deviceRow_rowTapped_withPendingRequest() {
        let request = LoginRequest.fixture()
        var device = DeviceListItem.fixture()
        device.pendingRequest = request

        subject.receive(.deviceRow(.rowTapped(device)))

        #expect(coordinator.routes.last == .loginRequest(request))
        #expect(coordinator.contexts.last is DeviceManagementProcessor)
    }

    /// `receive(_:)` does nothing when the device has no pending request.
    @Test
    func receive_deviceRow_rowTapped_noPendingRequest() {
        subject.receive(.deviceRow(.rowTapped(.fixture())))

        #expect(coordinator.routes.isEmpty)
    }

    /// `receive(_:)` dismisses the view.
    @Test
    func receive_dismiss() {
        subject.receive(.dismiss)

        #expect(coordinator.routes.last == .dismiss())
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
