import PhotosUI
import SwiftUI
import XCTest

@testable import BitwardenShared

class SendCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var sendRepository: MockSendRepository!
    var stackNavigator: MockStackNavigator!
    var subject: SendCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        errorReporter = MockErrorReporter()
        sendRepository = MockSendRepository()
        stackNavigator = MockStackNavigator()
        subject = SendCoordinator(
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                sendRepository: sendRepository
            ),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        errorReporter = nil
        sendRepository = nil
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
        let fileSelectionDelegate = MockFileSelectionDelegate()
        subject.navigate(to: .fileBrowser, context: fileSelectionDelegate)

        let data = Data("example".utf8)

        let viewController = MockUIDocumentPickerViewController()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("example.txt")

        // Write to a temporary file
        try data.write(to: url)

        subject.documentPicker(viewController, didPickDocumentsAt: [url])

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(fileSelectionDelegate.fileName, "example.txt")
        XCTAssertEqual(fileSelectionDelegate.data, data)

        // Clean up the temporary file
        try FileManager.default.removeItem(at: url)
    }

    /// `imagePickerController(_:,didFinishPickingMediaWithInfo:)` creates a filename for the photo
    /// and notifies the delegate.
    func test_imagePickerViewControllerDidFinishPickingMediaWithInfo() {
        let fileSelectionDelegate = MockFileSelectionDelegate()
        subject.navigate(to: .camera, context: fileSelectionDelegate)

        let viewController = UIImagePickerController()
        let image = UIImage(systemName: "doc.zipper")!
        subject.imagePickerController(viewController, didFinishPickingMediaWithInfo: [
            .originalImage: image,
        ])

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertTrue(fileSelectionDelegate.fileName!.hasPrefix("photo_"))
        XCTAssertEqual(fileSelectionDelegate.data, image.jpegData(compressionQuality: 1))
    }

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    func test_navigateTo_addItem_hasPremium() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(true)
        subject.navigate(to: .addItem)

        waitFor(!stackNavigator.actions.isEmpty)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        let viewController = try XCTUnwrap(
            navigationController.viewControllers.first as? UIHostingController<AddEditSendItemView>
        )
        let view = viewController.rootView
        XCTAssertTrue(view.store.state.hasPremium)
    }

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    func test_navigateTo_addItem_notHasPremium() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(false)
        subject.navigate(to: .addItem)

        waitFor(!stackNavigator.actions.isEmpty)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        let viewController = try XCTUnwrap(
            navigationController.viewControllers.first as? UIHostingController<AddEditSendItemView>
        )
        let view = viewController.rootView
        XCTAssertFalse(view.store.state.hasPremium)
    }

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    func test_navigateTo_addItem_hasPremiumError() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .failure(BitwardenTestError.example)
        subject.navigate(to: .addItem)

        waitFor(!stackNavigator.actions.isEmpty)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        let viewController = try XCTUnwrap(
            navigationController.viewControllers.first as? UIHostingController<AddEditSendItemView>
        )
        let view = viewController.rootView
        XCTAssertFalse(view.store.state.hasPremium)
    }

    /// `navigate(to:)` with `.camera` and without a file selection delegate does not present the
    /// camera screen.
    func test_navigateTo_camera_withoutDelegate() throws {
        subject.navigate(to: .camera, context: nil)
        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.camera` and with a file selection delegate presents the camera
    /// screen.
    func test_navigateTo_camera_withDelegate() throws {
        let delegate = MockFileSelectionDelegate()
        subject.navigate(to: .camera, context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)

        let viewController = try XCTUnwrap(action.view as? UIImagePickerController)
        XCTAssertIdentical(viewController.delegate, subject)
        XCTAssertEqual(viewController.sourceType, .camera)
        XCTAssertFalse(viewController.allowsEditing)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the current modally presented screen.
    func test_navigateTo_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.fileBrowser` and without a file selection delegate does not present
    /// the file browser screen.
    func test_navigateTo_fileBrowser_withoutDelegate() throws {
        subject.navigate(to: .fileBrowser, context: nil)
        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.fileBrowser` and with a file selection delegate presents the file
    /// browser screen.
    func test_navigateTo_fileBrowser_withDelegate() throws {
        let delegate = MockFileSelectionDelegate()
        subject.navigate(to: .fileBrowser, context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)

        let viewController = try XCTUnwrap(action.view as? UIDocumentPickerViewController)
        XCTAssertIdentical(viewController.delegate, subject)
        XCTAssertFalse(viewController.allowsMultipleSelection)
    }

    /// `navigate(to:)` with `.list` replaces the stack navigator's current stack with the send list
    /// screen.
    func test_navigateTo_list() throws {
        subject.navigate(to: .list)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is SendListView)
    }

    /// `navigate(to:)` with `.photoLibrary` and without a file selection delegate does not present
    /// the photo picker screen.
    func test_navigateTo_photoLibrary_withoutDelegate() throws {
        subject.navigate(to: .photoLibrary, context: nil)
        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.photoLibrary` and with a file selection delegate presents the photo
    /// picker screen.
    func test_navigateTo_photoLibrary_withDelegate() throws {
        let delegate = MockFileSelectionDelegate()
        subject.navigate(to: .photoLibrary, context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)

        let viewController = try XCTUnwrap(action.view as? PHPickerViewController)
        XCTAssertIdentical(viewController.delegate, subject)
        XCTAssertEqual(viewController.configuration.filter, .images)
        XCTAssertEqual(viewController.configuration.selectionLimit, 1)
    }

    /// `start()` initializes the coordinator's state correctly.
    func test_start() throws {
        subject.start()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is SendListView)
    }
}
