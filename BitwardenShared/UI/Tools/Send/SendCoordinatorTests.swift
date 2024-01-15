import PhotosUI
import SwiftUI
import XCTest

@testable import BitwardenShared

class SendCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var module: MockAppModule!
    var sendRepository: MockSendRepository!
    var stackNavigator: MockStackNavigator!
    var subject: SendCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        errorReporter = MockErrorReporter()
        module = MockAppModule()
        sendRepository = MockSendRepository()
        stackNavigator = MockStackNavigator()
        subject = SendCoordinator(
            module: module,
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
        module = nil
        sendRepository = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

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

        XCTAssertEqual(module.fileSelectionCoordinator.routes.last, .camera)
        XCTAssertTrue(module.fileSelectionCoordinator.isStarted)
        XCTAssertIdentical(module.fileSelectionDelegate, delegate)
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

        XCTAssertEqual(module.fileSelectionCoordinator.routes.last, .file)
        XCTAssertTrue(module.fileSelectionCoordinator.isStarted)
        XCTAssertIdentical(module.fileSelectionDelegate, delegate)
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

        XCTAssertEqual(module.fileSelectionCoordinator.routes.last, .photo)
        XCTAssertTrue(module.fileSelectionCoordinator.isStarted)
        XCTAssertIdentical(module.fileSelectionDelegate, delegate)
    }

    /// `start()` initializes the coordinator's state correctly.
    func test_start() throws {
        subject.start()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is SendListView)
    }
}
