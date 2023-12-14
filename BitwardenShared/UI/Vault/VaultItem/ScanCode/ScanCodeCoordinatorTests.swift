import AVFoundation
import SwiftUI
import XCTest

@testable import BitwardenShared

class ScanCodeCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var cameraService: MockCameraService!
    var delegate: MockScanCodeCoordinatorDelegate!
    var stackNavigator: MockStackNavigator!
    var subject: ScanCodeCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cameraService = MockCameraService()
        delegate = MockScanCodeCoordinatorDelegate()
        stackNavigator = MockStackNavigator()

        subject = ScanCodeCoordinator(
            delegate: delegate,
            services: ServiceContainer.withMocks(
                cameraService: cameraService
            ),
            stackNavigator: stackNavigator
        )
        cameraService.cameraAuthorizationStatus = .authorized
        cameraService.startResult = .success(AVCaptureSession())
    }

    override func tearDown() {
        super.tearDown()

        cameraService = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    func test_navigateTo_cancel() throws {
        subject.navigate(to: .dismiss)
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissed)
    }

    /// `navigate(to:)` with `.complete` instructs the delegate that the scan flow has
    /// completed.
    func test_navigateTo_complete() {
        let result = ScanResult(content: "example.com", codeType: .qr)
        subject.navigate(to: .complete(value: result))
        XCTAssertTrue(delegate.didCompleteScanCalled)
        XCTAssertEqual(delegate.didCompleteScanValue, "example.com")
    }

    /// `navigate(to:)` with `.scanCode` shows the scan view.
    func test_navigateTo_scanCode() throws {
        let task = Task {
            subject.navigate(to: .scanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ScanCodeView.self))
    }

    /// `navigate(to:)` with `.dismiss` dismisses the presented view.
    func test_navigate_dismiss() throws {
        let task = Task {
            subject.navigate(to: .scanCode)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        subject.navigate(to: .dismiss)
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissed)
    }

    /// `navigate(to:)` with `.setupTotpManual` presents the manual entry view.
    func test_navigateTo_setupTotpManual() throws {
        subject.navigate(to: .setupTotpManual)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is NavigationView<Text>)
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

    /// `start(manualEntry:)`  with `false` navigates to the scan code view.
    func test_start_manualEntry_false() throws {
        let task = Task {
            subject.start(manualEntry: false)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ScanCodeView.self))
    }

    /// `start(manualEntry:)`  with `true` navigates to the manual entry view.
    func test_start_manualEntry_true() throws {
        let task = Task {
            subject.start(manualEntry: true)
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is NavigationView<Text>)
    }

    /// `start()` navigates to the scan code view.
    func test_start_success() throws {
        let task = Task {
            subject.start()
        }
        waitFor(!stackNavigator.actions.isEmpty)
        task.cancel()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let view = action.view as? (any View)
        XCTAssertNotNil(try? view?.inspect().find(ScanCodeView.self))
    }
}

// MARK: - MockScanCodeCoordinatorDelegate

class MockScanCodeCoordinatorDelegate: ScanCodeCoordinatorDelegate {
    var didCancelScanCalled = false

    var didCompleteScanCalled = false
    var didCompleteScanValue: String?

    func didCancelScan() {
        didCancelScanCalled = true
    }

    func didCompleteScan(with value: String) {
        didCompleteScanCalled = true
        didCompleteScanValue = value
    }
}
