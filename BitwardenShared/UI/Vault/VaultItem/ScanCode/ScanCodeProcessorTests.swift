import XCTest

@testable import BitwardenShared

final class ScanCodeProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var cameraAuthorizationService: MockCameraAuthorizationService!
    var coordinator: MockCoordinator<VaultItemRoute>!
    var errorReporter: MockErrorReporter!
    var subject: ScanCodeProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cameraAuthorizationService = MockCameraAuthorizationService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        subject = ScanCodeProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                cameraAuthorizationService: cameraAuthorizationService,
                errorReporter: errorReporter
            ),
            state: .init()
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
        let error = CameraServiceError.unableToStartCaptureSession
        cameraAuthorizationService.startResult = .failure(error)
        await subject.perform(.appeared)
        XCTAssertEqual(
            errorReporter.errors as? [CameraServiceError],
            [error]
        )
    }

    /// `perform()` with `.appeared` sets up the camera.
    func test_perform_appeared_success() async {
        await subject.perform(.appeared)
        XCTAssertTrue(cameraAuthorizationService.didStart)
    }

    /// `perform()` with `.disappeared` stops the camera.
    func test_perform_disappeared_success() async {
        await subject.perform(.disappeared)
        XCTAssertTrue(cameraAuthorizationService.didStop)
    }

    /// `receive()` with `.dismissPressed` navigates to dismiss.
    func test_receive_dismissPressed() async {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes, [.dismiss])
    }

    /// `receive()` with `.dismissPressed` navigates to dismiss.
    func test_receive_manualEntryPressed() async {
        subject.receive(.manualEntryPressed)
        XCTAssertEqual(coordinator.routes, [])
    }
}
