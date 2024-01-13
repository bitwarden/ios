import UIKit
import XCTest

@testable import BitwardenShared

class AttachmentsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var cameraService: MockCameraService!
    var coordinator: MockCoordinator<VaultItemRoute>!
    var errorReporter: MockErrorReporter!
    var subject: AttachmentsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cameraService = MockCameraService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        subject = AttachmentsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                cameraService: cameraService,
                errorReporter: errorReporter
            ),
            state: AttachmentsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        cameraService = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.cameraViewPresentedChanged` updates the camera view presentation status.
    func test_receive_cameraViewPresentedChanged() throws {
        XCTAssertFalse(subject.state.cameraViewPresented)
        subject.receive(.cameraViewPresentedChanged(true))
        XCTAssertTrue(subject.state.cameraViewPresented)
    }

    /// `receive(_:)` with `.chooseFilePressed` shows the attachment options alert.
    func test_receive_chooseFilePressed() {
        subject.receive(.chooseFilePressed)
        XCTAssertEqual(coordinator.alertShown.last, .attachmentOptions(handler: { _ in }))
    }

    /// `receive(_:)` with `.dismissPressed` dismisses the view.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `receive(_:)` with `.imageChanged` updates the image in the state.
    func test_receive_imageChanged() throws {
        let testImage = UIImage(named: "AppIcon")
        subject.receive(.imageChanged(testImage))
        XCTAssertEqual(subject.state.image, testImage)
    }

    /// Selecting the camera option on the attachments alert checks for camera permissions and presents the camera view.
    func test_showCamera() async throws {
        cameraService.cameraAuthorizationStatus = .authorized

        subject.receive(.chooseFilePressed)

        let cameraAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions[1])
        await cameraAction.handler?(cameraAction, [])

        XCTAssertTrue(subject.state.cameraViewPresented)
    }

    /// Selecting the camera option on the attachments alert prompts the user to enable camera permissions if necessary.
    func test_showCamera_noPermission() async throws {
        cameraService.cameraAuthorizationStatus = .denied

        subject.receive(.chooseFilePressed)

        let cameraAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions[1])
        await cameraAction.handler?(cameraAction, [])

        XCTAssertFalse(subject.state.cameraViewPresented)
        // TODO: BIT-1466 alert to prompt user to enable camera permissions shows
    }
}
