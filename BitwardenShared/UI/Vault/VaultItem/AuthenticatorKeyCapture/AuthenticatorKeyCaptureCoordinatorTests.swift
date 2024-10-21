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
    @MainActor
    func test_navigateTo_addManual() {
        let entry = "manuallyManagedMagic"
        subject.navigate(to: .addManual(entry: entry))
        XCTAssertTrue(delegate.didCompleteCaptureCalled)
        XCTAssertEqual(delegate.didCompleteCaptureValue, entry)
        XCTAssertNotNil(delegate.capturedCaptureCoordinator)
    }

    /// `navigate(to:)` with `.complete` instructs the delegate that the capture flow has
    /// completed.
    @MainActor
    func test_navigateTo_complete() {
        let result = ScanResult(content: "example.com", codeType: .qr)
        subject.navigate(to: .complete(value: result))
        XCTAssertTrue(delegate.didCompleteCaptureCalled)
        XCTAssertEqual(delegate.didCompleteCaptureValue, "example.com")
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

    /// `navigate(to:)` with `.setupTotpManual` presents the manual entry view.
    @MainActor
    func test_navigateTo_setupTotpManual() throws {
        subject.navigate(to: .manualKeyEntry)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ManualEntryView.self))
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
    func test_navigateTo_scanCode() throws {
        cameraService.deviceHasCamera = true
        let task = Task {
            await subject.handleEvent(.showScanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ScanCodeView.self))
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
    func test_navigateAsyncTo_scanCode() throws {
        cameraService.deviceHasCamera = true
        let task = Task {
            await subject.handleEvent(.showScanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ScanCodeView.self))
    }

    /// `navigate(to:)` with `.scanCode` shows the scan view.
    @MainActor
    func test_navigateAsyncTo_scanCode_cameraSessionError() throws {
        cameraService.deviceHasCamera = true
        struct TestError: Error, Equatable {}
        cameraService.startResult = .failure(TestError())
        let task = Task {
            await subject.handleEvent(.showScanCode)
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
    @MainActor
    func test_navigateAsyncTo_scanCode_declineAuthorization() throws {
        cameraService.deviceHasCamera = true
        cameraService.cameraAuthorizationStatus = .denied
        let task = Task {
            await subject.handleEvent(.showScanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ManualEntryView.self))
    }

    /// `navigate(to:)` with `.scanCode` shows the scan view.
    @MainActor
    func test_navigateAsyncTo_scanCode_noCamera() throws {
        cameraService.deviceHasCamera = false
        let task = Task {
            await subject.handleEvent(.showScanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ManualEntryView.self))
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
    var didCompleteCaptureValue: String?

    /// A flag to capture a `showCameraScan` call.
    var didRequestCamera: Bool = false

    /// A flag to capture a `showManualEntry` call.
    var didRequestManual: Bool = false

    func didCancelScan() {
        didCancelScanCalled = true
    }

    func didCompleteCapture(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>,
        with value: String
    ) {
        didCompleteCaptureCalled = true
        capturedCaptureCoordinator = captureCoordinator
        didCompleteCaptureValue = value
    }

    func showCameraScan(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>
    ) {
        didRequestCamera = true
        capturedCaptureCoordinator = captureCoordinator
    }

    func showManualEntry(
        _ captureCoordinator: AnyCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>
    ) {
        didRequestManual = true
        capturedCaptureCoordinator = captureCoordinator
    }
}
