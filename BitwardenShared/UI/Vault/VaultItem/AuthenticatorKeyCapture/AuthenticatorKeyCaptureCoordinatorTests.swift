import AVFoundation
import SwiftUI
import XCTest

@testable import BitwardenShared

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
                errorReporter: errorReporter
            ),
            stackNavigator: stackNavigator
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
    /// completed.
    func test_navigateTo_addManual() {
        let entry = "manuallyManagedMagic"
        subject.navigate(to: .addManual(entry: entry))
        XCTAssertTrue(delegate.didCompleteCaptureCalled)
        XCTAssertEqual(delegate.didCompleteCaptureValue, entry)
        XCTAssertNotNil(delegate.capturedCaptureCoordinator)
    }

    /// `navigate(to:)` with `.complete` instructs the delegate that the capture flow has
    /// completed.
    func test_navigateTo_complete() {
        let result = ScanResult(content: "example.com", codeType: .qr)
        subject.navigate(to: .complete(value: result))
        XCTAssertTrue(delegate.didCompleteCaptureCalled)
        XCTAssertEqual(delegate.didCompleteCaptureValue, "example.com")
    }

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    func test_navigateTo_dismiss_noAction() throws {
        subject.navigate(to: .dismiss())
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    func test_navigateTo_dismiss_withAction() throws {
        var didRun = false
        subject.navigate(to: .dismiss(DismissAction(action: { didRun = true })))
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissedWithCompletionHandler)
        XCTAssertTrue(didRun)
    }

    /// `navigate(to:)` with `.setupTotpManual` presents the manual entry view.
    func test_navigateTo_setupTotpManual() throws {
        subject.navigate(to: .manualKeyEntry)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ManualEntryView.self))
    }

    /// `showLoadingOverlay()` and `hideLoadingOverlay()` can be used to show and hide the loading overlay.
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
    func test_waitAndNavigateTo_scanCode() throws {
        cameraService.deviceHasCamera = true
        let task = Task {
            await subject.navigate(asyncTo: .scanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ScanCodeView.self))
    }

    /// `navigate(to:)` with `.scanCode` shows the scan view.
    func test_waitAndNavigateTo_scanCode_cameraSessionError() throws {
        cameraService.deviceHasCamera = true
        struct TestError: Error, Equatable {}
        cameraService.startResult = .failure(TestError())
        let task = Task {
            await subject.navigate(asyncTo: .scanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? TestError, TestError())
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ManualEntryView.self))
    }

    /// `navigate(to:)` with `.scanCode` shows the scan view.
    func test_waitAndNavigateTo_scanCode_declineAuthorization() throws {
        cameraService.deviceHasCamera = true
        cameraService.cameraAuthorizationStatus = .denied
        let task = Task {
            await subject.navigate(asyncTo: .scanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ManualEntryView.self))
    }

    /// `navigate(to:)` with `.scanCode` shows the scan view.
    func test_waitAndNavigateTo_scanCode_noCamera() throws {
        cameraService.deviceHasCamera = false
        let task = Task {
            await subject.navigate(asyncTo: .scanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ManualEntryView.self))
    }
}

// MARK: - MockAuthenticatorKeyCaptureDelegate

class MockAuthenticatorKeyCaptureDelegate: AuthenticatorKeyCaptureDelegate {
    var capturedCaptureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute>?
    var didCancelScanCalled = false

    var didCompleteCaptureCalled = false
    var didCompleteCaptureValue: String?

    func didCancelScan() {
        didCancelScanCalled = true
    }

    func didCompleteCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute>,
        with value: String
    ) {
        didCompleteCaptureCalled = true
        capturedCaptureCoordinator = captureCoordinator
        didCompleteCaptureValue = value
    }
}
