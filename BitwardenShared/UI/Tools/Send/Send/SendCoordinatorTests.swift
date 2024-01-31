import BitwardenSdk
import PhotosUI
import SwiftUI
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
    func test_navigateTo_addItem_hasPremium_withDelegate() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(true)
        subject.navigate(to: .addItem(), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .add(content: nil, hasPremium: true))
    }

    /// `navigate(to:)` with `.addItem` and without a delegate does not present the add send item
    /// screen.
    func test_navigateTo_addItem_hasPremium_withoutDelegate() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(true)
        subject.navigate(to: .addItem(), context: nil)

        XCTAssertFalse(module.sendItemCoordinator.isStarted)
        XCTAssertTrue(module.sendItemCoordinator.routes.isEmpty)
    }

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    func test_navigateTo_addItem_notHasPremium() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(false)
        subject.navigate(to: .addItem(), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .add(content: nil, hasPremium: false))
    }

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    func test_navigateTo_addItem_hasPremiumError() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .failure(BitwardenTestError.example)
        subject.navigate(to: .addItem(), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .add(content: nil, hasPremium: false))
    }

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    func test_navigateTo_addItem_fileType_hasPremium_withDelegate() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(true)
        subject.navigate(to: .addItem(type: .file), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .add(content: .type(.file), hasPremium: true))
    }

    /// `navigate(to:)` with `.addItem` and without a delegate does not present the add send item
    /// screen.
    func test_navigateTo_addItem_fileType_hasPremium_withoutDelegate() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(true)
        subject.navigate(to: .addItem(type: .file), context: nil)

        XCTAssertFalse(module.sendItemCoordinator.isStarted)
        XCTAssertTrue(module.sendItemCoordinator.routes.isEmpty)
    }

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    func test_navigateTo_addItem_fileType_notHasPremium() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(false)
        subject.navigate(to: .addItem(type: .file), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .add(content: .type(.file), hasPremium: false))
    }

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    func test_navigateTo_addItem_fileType_hasPremiumError() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .failure(BitwardenTestError.example)
        subject.navigate(to: .addItem(type: .file), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .add(content: .type(.file), hasPremium: false))
    }

    /// `navigate(to:)` with `.dismiss` dismisses the current modally presented screen.
    func test_navigateTo_dismiss() throws {
        subject.navigate(to: .dismiss())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.editItem` presents the add send item screen.
    func test_navigateTo_editItem_hasPremium_withDelegate() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(true)
        let sendView = SendView.fixture()
        subject.navigate(to: .editItem(sendView), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .edit(sendView, hasPremium: true))
    }

    /// `navigate(to:)` with `.editItem` and without a delegate does not present the add send item
    /// screen.
    func test_navigateTo_editItem_hasPremium_withoutDelegate() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(true)
        let sendView = SendView.fixture()
        subject.navigate(to: .editItem(sendView), context: nil)

        XCTAssertFalse(module.sendItemCoordinator.isStarted)
        XCTAssertTrue(module.sendItemCoordinator.routes.isEmpty)
    }

    /// `navigate(to:)` with `.editItem` presents the add send item screen.
    func test_navigateTo_editItem_notHasPremium() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .success(false)
        let sendView = SendView.fixture()
        subject.navigate(to: .editItem(sendView), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .edit(sendView, hasPremium: false))
    }

    /// `navigate(to:)` with `.editItem` presents the add send item screen.
    func test_navigateTo_editItem_hasPremiumError() throws {
        sendRepository.doesActivateAccountHavePremiumResult = .failure(BitwardenTestError.example)
        let sendView = SendView.fixture()
        subject.navigate(to: .editItem(sendView), context: sendItemDelegate)

        waitFor(!stackNavigator.actions.isEmpty)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)

        XCTAssertTrue(module.sendItemCoordinator.isStarted)
        XCTAssertEqual(module.sendItemCoordinator.routes.last, .edit(sendView, hasPremium: false))
    }

    /// `navigate(to:)` with `.group` pushes the send list screen for the type onto the stack.
    func test_navigateTo_group() throws {
        subject.navigate(to: .group(.file))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)

        let view = try XCTUnwrap(action.view as? BitwardenShared.SendListView)
        XCTAssertEqual(view.store.state.type, .file)
    }

    /// `navigate(to:)` with `.list` replaces the stack navigator's current stack with the send list
    /// screen.
    func test_navigateTo_list() throws {
        subject.navigate(to: .list)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is BitwardenShared.SendListView)
    }

    /// `navigate(to:)` with `.share` presents the share sheet.
    func test_navigateTo_share() throws {
        subject.navigate(to: .share(url: .example))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UIActivityViewController)
    }

    /// `start()` initializes the coordinator's state correctly.
    func test_start() throws {
        subject.start()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is BitwardenShared.SendListView)
    }
}
