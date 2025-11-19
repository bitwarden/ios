// swiftlint:disable:this file_name
import AVFoundation
import BitwardenKit
import BitwardenKitMocks
import SwiftUI
import XCTest

@testable import BitwardenShared

class AuthenticatorKeyCaptureCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var cameraService: MockCameraService!
    var delegate: MockAuthenticatorKeyCaptureDelegate!
    var errorReporter: MockErrorReporter!
    var stackNavigator: MockStackNavigator!
    var subject: AuthenticatorKeyCaptureCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        cameraService = MockCameraService()
        delegate = MockAuthenticatorKeyCaptureDelegate()
        errorReporter = MockErrorReporter()
        stackNavigator = MockStackNavigator()

        subject = AuthenticatorKeyCaptureCoordinator(
            appExtensionDelegate: appExtensionDelegate,
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

        appExtensionDelegate = nil
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
        with value: String,
    ) {
        didCompleteCaptureCalled = true
        capturedCaptureCoordinator = captureCoordinator
        didCompleteCaptureValue = value
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
