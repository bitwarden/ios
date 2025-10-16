import BitwardenKitMocks
import BitwardenSdk
import PhotosUI
import SwiftUI
import TestHelpers
import XCTest

@testable import BitwardenShared

class SendCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var module: MockAppModule!
    var sendItemDelegate: MockSendItemDelegate!
    var sendRepository: MockSendRepository!
    var stackNavigator: MockStackNavigator!
    var subject: SendCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        errorReporter = MockErrorReporter()
        module = MockAppModule()
        sendItemDelegate = MockSendItemDelegate()
        sendRepository = MockSendRepository()
        stackNavigator = MockStackNavigator()
        subject = SendCoordinator(
            module: module,
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                sendRepository: sendRepository,
            ),
            stackNavigator: stackNavigator,
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
    @MainActor
    func test_navigateTo_addItem_withDelegate() throws {
        subject.navigate(to: .addItem(), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .add(content: nil))
    }

    /// `navigate(to:)` with `.addItem` and without a delegate does not present the add send item
    /// screen.
    @MainActor
    func test_navigateTo_addItem_withoutDelegate() throws {
        subject.navigate(to: .addItem(), context: nil)

        XCTAssertFalse(module.sendItemCoordinator.isStarted)
        XCTAssertTrue(module.sendItemCoordinator.routes.isEmpty)
    }

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    @MainActor
    func test_navigateTo_addItem_fileType_withDelegate() throws {
        subject.navigate(to: .addItem(type: .file), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .add(content: .type(.file)))
    }

    /// `navigate(to:)` with `.addItem` and without a delegate does not present the add send item
    /// screen.
    @MainActor
    func test_navigateTo_addItem_fileType_withoutDelegate() throws {
        subject.navigate(to: .addItem(type: .file), context: nil)

        XCTAssertFalse(module.sendItemCoordinator.isStarted)
        XCTAssertTrue(module.sendItemCoordinator.routes.isEmpty)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the current modally presented screen.
    @MainActor
    func test_navigateTo_dismiss() throws {
        subject.navigate(to: .dismiss())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.editItem` presents the add send item screen.
    @MainActor
    func test_navigateTo_editItem_withDelegate() throws {
        let sendView = SendView.fixture()
        subject.navigate(to: .editItem(sendView), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .edit(sendView))
    }

    /// `navigate(to:)` with `.editItem` and without a delegate does not present the add send item
    /// screen.
    @MainActor
    func test_navigateTo_editItem_withoutDelegate() throws {
        let sendView = SendView.fixture()
        subject.navigate(to: .editItem(sendView), context: nil)

        XCTAssertFalse(module.sendItemCoordinator.isStarted)
        XCTAssertTrue(module.sendItemCoordinator.routes.isEmpty)
    }

    /// `navigate(to:)` with `.group` pushes the send list screen for the type onto the stack.
    @MainActor
    func test_navigateTo_group() throws {
        subject.navigate(to: .group(.file))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)

        let view = try XCTUnwrap(
            (action.view as? UIHostingController<BitwardenShared.SendListView>)?.rootView,
        )
        XCTAssertEqual(view.store.state.type, .file)
    }

    /// `navigate(to:)` with `.list` replaces the stack navigator's current stack with the send list
    /// screen.
    @MainActor
    func test_navigateTo_list() throws {
        subject.navigate(to: .list)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is BitwardenShared.SendListView)
    }

    /// `navigate(to:)` with `.share` presents the share sheet.
    @MainActor
    func test_navigateTo_share() throws {
        subject.navigate(to: .share(url: .example))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIActivityViewController)
    }

    /// `navigate(to:)` with `.viewItem` presents the view send item screen
    @MainActor
    func test_navigateTo_viewItem() throws {
        let sendView = SendView.fixture()
        subject.navigate(to: .viewItem(sendView), context: sendItemDelegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .view(sendView))
    }

    /// `start()` initializes the coordinator's state correctly.
    @MainActor
    func test_start() throws {
        subject.start()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is BitwardenShared.SendListView)
    }
}
