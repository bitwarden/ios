import PhotosUI
import XCTest

@testable import BitwardenShared

// MARK: - FileSelectionCoordinatorTests

class FileSelectionCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var cameraService: MockCameraService!
    var delegate: MockFileSelectionDelegate!
    var errorReporter: MockErrorReporter!
    var stackNavigator: MockStackNavigator!
    var subject: FileSelectionCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        cameraService = MockCameraService()
        delegate = MockFileSelectionDelegate()
        errorReporter = MockErrorReporter()
        stackNavigator = MockStackNavigator()
        subject = FileSelectionCoordinator(
            delegate: delegate,
            services: ServiceContainer.withMocks(
                cameraService: cameraService,
                errorReporter: errorReporter
            ),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        delegate = nil
        errorReporter = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `documentPickerWasCancelled()` dismisses the view controller.
    func test_documentPickerWasCancelled() {
        let viewController = MockUIDocumentPickerViewController()
        subject.documentPickerWasCancelled(viewController)
        XCTAssertTrue(viewController.didDismiss)
    }

    /// `documentPicker(_,didPickDocumentsAt:)` reads the file at the specified URL and notifies the
    /// delegate.
    func test_documentPickerDidPickDocumentsAt_withUrl() throws {
        subject.navigate(to: .file)

        let data = Data("example".utf8)

        let viewController = MockUIDocumentPickerViewController()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("example.txt")

        // Write to a temporary file
        try data.write(to: url)

        subject.documentPicker(viewController, didPickDocumentsAt: [url])

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(delegate.fileName, "example.txt")
        XCTAssertEqual(delegate.data, data)

        // Clean up the temporary file
        try FileManager.default.removeItem(at: url)
    }

    /// `imagePickerController(_:,didFinishPickingMediaWithInfo:)` creates a filename for the photo
    /// and notifies the delegate.
    func test_imagePickerViewControllerDidFinishPickingMediaWithInfo() throws {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            throw XCTSkip("Unable to unit test UIImagePickerController with a camera input on CI")
        }

        subject.navigate(to: .camera)

        let viewController = UIImagePickerController()
        let image = UIImage(systemName: "doc.zipper")!
        subject.imagePickerController(viewController, didFinishPickingMediaWithInfo: [
            .originalImage: image,
        ])

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertTrue(delegate.fileName!.hasPrefix("photo_"))
        XCTAssertEqual(delegate.data, image.jpegData(compressionQuality: 1))
    }

    /// `navigate(to:)` with `.camera` and with camera authorization presents the camera screen.
    func test_navigateTo_camera_authorized() throws {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            throw XCTSkip("Unable to unit test UIImagePickerController with a camera input on CI")
        }

        cameraService.cameraAuthorizationStatus = .authorized
        let delegate = MockFileSelectionDelegate()
        subject.navigate(to: .camera, context: delegate)

        waitFor(!stackNavigator.actions.isEmpty)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)

        let viewController = try XCTUnwrap(action.view as? UIImagePickerController)
        XCTAssertIdentical(viewController.delegate, subject)
        XCTAssertEqual(viewController.sourceType, .camera)
        XCTAssertFalse(viewController.allowsEditing)
    }

    /// `navigate(to:)` with `.camera` and without camera authorization does not present the camera
    /// screen.
    func test_navigateTo_camera_denied() throws {
        cameraService.cameraAuthorizationStatus = .denied
        let delegate = MockFileSelectionDelegate()
        subject.navigate(to: .camera, context: delegate)

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `navigate(to:)` with `.fileBrowser` presents the file browser screen.
    func test_navigateTo_file() throws {
        let delegate = MockFileSelectionDelegate()
        subject.navigate(to: .file, context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)

        let viewController = try XCTUnwrap(action.view as? UIDocumentPickerViewController)
        XCTAssertIdentical(viewController.delegate, subject)
        XCTAssertFalse(viewController.allowsMultipleSelection)
    }
}
