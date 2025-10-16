import AVFoundation
import BitwardenKit
import BitwardenKitMocks
import SwiftUI
import XCTest

@testable import AuthenticatorShared

class AuthenticatorKeyCaptureCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var cameraService: MockCameraService!
    var delegate: MockAuthenticatorKeyCaptureDelegate!
    var errorReporter: MockErrorReporter!
    var stackNavigator: MockStackNavigator!
    var subject: AuthenticatorKeyCaptureCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cameraService = MockCameraService()
        delegate = MockAuthenticatorKeyCaptureDelegate()
        errorReporter = MockErrorReporter()
        stackNavigator = MockStackNavigator()

        subject = AuthenticatorKeyCaptureCoordinator(
            delegate: delegate,
            services: ServiceContainer.withMocks(
                cameraService: cameraService,
                errorReporter: errorReporter,
            ),
            stackNavigator: stackNavigator,
        )
        cameraService.cameraAuthorizationStatus = .authorized
        cameraService.startResult = .success(AVCaptureSession())
    }

    override func tearDown() {
        super.tearDown()

        cameraService = nil
        errorReporter = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.addManual` instructs the delegate that the capture flow has
    /// completed. Passing `false` to `sendToBitwarden` passes `false` to the delegate.
    @MainActor
    func test_navigateTo_addManual() {
        delegate.didCompleteManualCaptureSendToBitwarden = true
        let name = "manual name"
        let entry = "manuallyManagedMagic"
        subject.navigate(to: .addManual(key: entry, name: name, sendToBitwarden: false))
        XCTAssertTrue(delegate.didCompleteManualCaptureCalled)
        XCTAssertEqual(delegate.didCompleteManualCaptureKey, entry)
        XCTAssertEqual(delegate.didCompleteManualCaptureName, name)
        XCTAssertFalse(delegate.didCompleteManualCaptureSendToBitwarden)
        XCTAssertNotNil(delegate.capturedCaptureCoordinator)
    }

    /// `navigate(to:)` with `.addManual` instructs the delegate that the capture flow has
    /// completed. Passing `true` to `sendToBitwarden` passes `true` to the delegate.
    @MainActor
    func test_navigateTo_addManual_sendToBitwarden() {
        let name = "manual name"
        let entry = "manuallyManagedMagic"
        subject.navigate(to: .addManual(key: entry, name: name, sendToBitwarden: true))
        XCTAssertTrue(delegate.didCompleteManualCaptureCalled)
        XCTAssertEqual(delegate.didCompleteManualCaptureKey, entry)
        XCTAssertEqual(delegate.didCompleteManualCaptureName, name)
        XCTAssertTrue(delegate.didCompleteManualCaptureSendToBitwarden)
        XCTAssertNotNil(delegate.capturedCaptureCoordinator)
    }

    /// `navigate(to:)` with `.complete` instructs the delegate that the capture flow has
    /// completed.
    @MainActor
    func test_navigateTo_complete() {
        let result = ScanResult(content: "example.com", codeType: .qr)
        subject.navigate(to: .complete(value: result))
        XCTAssertTrue(delegate.didCompleteAutomaticCaptureCalled)
        XCTAssertEqual(delegate.didCompleteAutomaticCaptureKey, "example.com")
        XCTAssertNil(delegate.didCompleteCaptureName)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_navigateTo_dismiss_noAction() throws {
        subject.navigate(to: .dismiss())
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_navigateTo_dismiss_withAction() throws {
        var didRun = false
        subject.navigate(to: .dismiss(DismissAction(action: { didRun = true })))
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissedWithCompletionHandler)
        XCTAssertTrue(didRun)
    }

    /// `navigate(to:)` with `.setupTotpManual` presents the manual entry view. When the camera is
    /// present but the user has denied access, it sets `deviceSupportsCamera` to `false`.
    @MainActor
    func test_navigateTo_setupTotpManual_cameraNotAuthorized() throws {
        cameraService.deviceHasCamera = true
        cameraService.cameraAuthorizationStatus = .denied
        subject.navigate(to: .manualKeyEntry)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? ManualEntryView)
        XCTAssertFalse(view.store.state.deviceSupportsCamera)
    }

    /// `navigate(to:)` with `.setupTotpManual` presents the manual entry view. When the camera is
    /// present and `.authorized`, it sets `deviceSupportsCamera` to `true`.
    @MainActor
    func test_navigateTo_setupTotpManual_cameraPresentAndAuthorized() throws {
        cameraService.deviceHasCamera = true
        cameraService.cameraAuthorizationStatus = .authorized
        subject.navigate(to: .manualKeyEntry)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? ManualEntryView)
        XCTAssertTrue(view.store.state.deviceSupportsCamera)
    }

    /// `navigate(to:)` with `.setupTotpManual` presents the manual entry view. When the camera is
    /// not present, it sets `deviceSupportsCamera` to `false`.
    @MainActor
    func test_navigateTo_setupTotpManual_noCamera() throws {
        cameraService.deviceHasCamera = false
        subject.navigate(to: .manualKeyEntry)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? ManualEntryView)
        XCTAssertFalse(view.store.state.deviceSupportsCamera)
    }

    /// `navigate(to:)` with `.setupTotpManual` presents the manual entry view.
    @MainActor
    func test_navigateTo_setupTotpManual_nonEmptyStack() throws {
        stackNavigator.isEmpty = false
        subject.navigate(to: .manualKeyEntry)
        waitFor(delegate.didRequestManual)
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `navigate(to:)` with `.scanCode` shows the scan view.
    @MainActor
    func test_navigateTo_scanCode_nonEmptyStack() throws {
        stackNavigator.isEmpty = false
        cameraService.deviceHasCamera = true
        let task = Task {
            await subject.handleEvent(.showScanCode)
        }
        waitFor(delegate.didRequestCamera)
        task.cancel()
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
    @MainActor
    func test_show_hide_loadingOverlay() throws {
        stackNavigator.rootViewController = UIViewController()
        try setKeyWindowRoot(viewController: XCTUnwrap(stackNavigator.rootViewController))

        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.showLoadingOverlay(LoadingOverlayState(title: "Loading..."))
        XCTAssertNotNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))

        subject.hideLoadingOverlay()
        waitFor { window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag) == nil }
        XCTAssertNil(window.viewWithTag(LoadingOverlayDisplayHelper.overlayViewTag))
    }

    /// `navigate(to:)` with `.scanCode` shows the scan view.
    @MainActor
    func test_navigateAsyncTo_scanCode_nonEmptyStack() throws {
        stackNavigator.isEmpty = false
        cameraService.deviceHasCamera = true
        let task = Task {
            await subject.handleEvent(.showScanCode)
        }
        waitFor(delegate.didRequestCamera)
        task.cancel()
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}

// MARK: - MockAuthenticatorKeyCaptureDelegate

class MockAuthenticatorKeyCaptureDelegate: AuthenticatorKeyCaptureDelegate {
    var capturedCaptureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>?
    var didCancelScanCalled = false

    var didCompleteCaptureCalled = false
    var didCompleteCaptureKey: String?
    var didCompleteCaptureName: String?

    var didCompleteAutomaticCaptureCalled = false
    var didCompleteAutomaticCaptureKey: String?

    var didCompleteManualCaptureCalled = false
    var didCompleteManualCaptureKey: String?
    var didCompleteManualCaptureName: String?
    var didCompleteManualCaptureSendToBitwarden = false

    /// A flag to capture a `showCameraScan` call.
    var didRequestCamera: Bool = false

    /// A flag to capture a `showManualEntry` call.
    var didRequestManual: Bool = false

    func didCancelScan() {
        didCancelScanCalled = true
    }

    func didCompleteCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        key: String,
        name: String?,
    ) {
        didCompleteCaptureCalled = true
        capturedCaptureCoordinator = captureCoordinator
        didCompleteCaptureKey = key
        didCompleteCaptureName = name
    }

    func didCompleteAutomaticCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        key: String,
    ) {
        didCompleteAutomaticCaptureCalled = true
        capturedCaptureCoordinator = captureCoordinator
        didCompleteAutomaticCaptureKey = key
    }

    func didCompleteManualCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        key: String,
        name: String,
        sendToBitwarden: Bool,
    ) {
        didCompleteManualCaptureCalled = true
        capturedCaptureCoordinator = captureCoordinator
        didCompleteManualCaptureKey = key
        didCompleteManualCaptureName = name
        didCompleteManualCaptureSendToBitwarden = sendToBitwarden
    }

    func showCameraScan(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
    ) {
        didRequestCamera = true
        capturedCaptureCoordinator = captureCoordinator
    }

    func showManualEntry(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
    ) {
        didRequestManual = true
        capturedCaptureCoordinator = captureCoordinator
    }
}
