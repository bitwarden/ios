import AVFoundation
import XCTest

@testable import AuthenticatorShared

final class ScanCodeProcessorTests: AuthenticatorTestCase {
    // MARK: Properties

    var cameraService: MockCameraService!
    var coordinator: MockCoordinator<AuthenticatorKeyCaptureRoute, AuthenticatorKeyCaptureEvent>!
    var errorReporter: MockErrorReporter!
    var subject: ScanCodeProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cameraService = MockCameraService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        subject = ScanCodeProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                cameraService: cameraService,
                errorReporter: errorReporter
            ),
            state: ScanCodeState(showManualEntry: true)
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform()` with `.appeared` logs errors when starting the camera fails.
    func test_perform_appeared_failure() async {
        cameraService.deviceHasCamera = false
        await subject.perform(.appeared)
        XCTAssertEqual(coordinator.routes, [.manualKeyEntry])
    }

    /// `perform()` with `.appeared` sets up the camera observation and responds to QR code scans
    func test_perform_appeared_qrScan() {
        let publisher = MockCameraService.ScanPublisher(nil)
        cameraService.startResult = .success(AVCaptureSession())
        cameraService.resultsPublisher = publisher
        let task = Task {
            await subject.perform(.appeared)
        }
        let result = ScanResult(content: "123", codeType: .qr)
        publisher.send(result)
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()
        XCTAssertEqual(coordinator.routes.first, .complete(value: result))
    }

    /// `perform()` with `.appeared` sets up the camera.
    func test_perform_appeared_noCamera() async {
        cameraService.deviceHasCamera = false
        await subject.perform(.appeared)
        XCTAssertFalse(cameraService.didStart)
        XCTAssertEqual(coordinator.routes, [.manualKeyEntry])
    }

    /// `perform()` with `.disappeared` stops the camera.
    func test_perform_disappeared_success() async {
        await subject.perform(.disappeared)
        XCTAssertTrue(cameraService.didStop)
    }

    /// `receive()` with `.dismissPressed` navigates to dismiss.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes, [.dismiss()])
    }

    /// `receive()` with `.manualEntryPressed` navigates to `.setupTotpManual`.
    func test_receive_manualEntryPressed() async {
        subject.receive(.manualEntryPressed)
        XCTAssertEqual(coordinator.routes, [.manualKeyEntry])
    }
}
