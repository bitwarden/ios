// swiftlint:disable:this file_name
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
