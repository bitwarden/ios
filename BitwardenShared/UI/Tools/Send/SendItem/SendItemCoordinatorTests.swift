import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SendItemCoordinatorTests

class SendItemCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockSendItemDelegate!
    var errorReporter: MockErrorReporter!
    var module: MockAppModule!
    var sendRepository: MockSendRepository!
    var stackNavigator: MockStackNavigator!
    var subject: SendItemCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        delegate = MockSendItemDelegate()
        errorReporter = MockErrorReporter()
        module = MockAppModule()
        sendRepository = MockSendRepository()
        stackNavigator = MockStackNavigator()
        subject = SendItemCoordinator(
            delegate: delegate,
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
        delegate = nil
        errorReporter = nil
        module = nil
        sendRepository = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.add()` shows the add item screen.
    @MainActor
    func test_navigateTo_add_noContent() throws {
        subject.navigate(to: .add(content: nil))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertEqual(view.store.state.mode, .add)
    }

    /// `navigate(to:)` with `.add()` shows the add send item screen with prefilled file content.
    @MainActor
    func test_navigateTo_add_fileContent() throws {
        subject.navigate(
            to: .add(
                content: .file(
                    fileName: "test file",
                    fileData: Data("test data".utf8),
                ),
            ),
        )

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertEqual(view.store.state.mode, .shareExtension(.empty()))
        XCTAssertEqual(view.store.state.type, .file)
        XCTAssertEqual(view.store.state.text, "")
        XCTAssertEqual(view.store.state.fileName, "test file")
        XCTAssertEqual(view.store.state.fileData, Data("test data".utf8))
    }

    /// `navigate(to:)` with `.add()` shows the add item screen with prefilled text content.
    @MainActor
    func test_navigateTo_add_textContent() throws {
        subject.navigate(to: .add(content: .text("test")))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertEqual(
            view.store.state.mode,
            .shareExtension(.empty()),
        )
        XCTAssertEqual(view.store.state.type, .text)
        XCTAssertEqual(view.store.state.text, "test")
        XCTAssertNil(view.store.state.fileName)
        XCTAssertNil(view.store.state.fileData)
    }

    /// `navigate(to:)` with `.add()` shows the add send item screen with prefilled type content.
    @MainActor
    func test_navigateTo_add_typeContent() throws {
        subject.navigate(to: .add(content: .type(.file)))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertEqual(view.store.state.mode, .add)
        XCTAssertEqual(view.store.state.type, .file)
        XCTAssertEqual(view.store.state.text, "")
        XCTAssertEqual(view.store.state.fileName, nil)
        XCTAssertEqual(view.store.state.fileData, nil)
    }

    /// `navigate(to:)` with `.cancel` notifies the delegate.
    @MainActor
    func test_navigateTo_cancel() {
        subject.navigate(to: .cancel)

        XCTAssertTrue(delegate.didSendItemCancelled)
    }

    /// `navigate(to:)` with `.complete` notifies the delegate.
    @MainActor
    func test_navigateTo_complete() {
        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        subject.navigate(to: .complete(sendView))

        XCTAssertTrue(delegate.didSendItemCompleted)
        XCTAssertEqual(delegate.sendItemCompletedSendView, sendView)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the current modally presented screen.
    @MainActor
    func test_navigateTo_dismiss() throws {
        subject.navigate(to: .dismiss())

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.edit` shows the edit screen.
    @MainActor
    func test_navigateTo_edit() throws {
        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        subject.navigate(to: .edit(sendView))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertEqual(view.store.state.name, "Name")
        XCTAssertEqual(view.store.state.mode, .edit)
    }

    /// `navigate(to:)` with `.edit` with a non empty stack presents a new send item coordinator.
    @MainActor
    func test_navigateTo_edit_presentsCoordinator() throws {
        stackNavigator.isEmpty = false

        subject.navigate(to: .edit(.fixture()), context: nil)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)
        XCTAssertEqual(module.sendItemCoordinator.routes, [.edit(.fixture())])
    }

    /// `navigate(to:)` with `.fileSelection` and with a file selection delegate presents the file
    /// selection screen.
    @MainActor
    func test_navigateTo_fileSelection_withDelegate() throws {
        let delegate = MockFileSelectionDelegate()
        subject.navigate(to: .fileSelection(.camera), context: delegate)

        XCTAssertEqual(module.fileSelectionCoordinator.routes.last, .camera)
        XCTAssertTrue(module.fileSelectionCoordinator.isStarted)
        XCTAssertIdentical(module.fileSelectionDelegate, delegate)
    }

    /// `navigate(to:)` with `.fileSelection` and without a file selection delegate does not present the
    /// file selection screen.
    @MainActor
    func test_navigateTo_fileSelection_withoutDelegate() throws {
        subject.navigate(to: .fileSelection(.camera), context: nil)
        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.generator` and a delegate presents the generator screen.
    @MainActor
    func test_navigateTo_generator_withDelegate() throws {
        let delegate = MockGeneratorCoordinatorDelegate()
        subject.navigate(to: .generator, context: delegate)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is UINavigationController)
        XCTAssertEqual(module.generatorCoordinator.routes.last, .generator(staticType: .password))
        XCTAssertTrue(module.generatorCoordinator.isStarted)
    }

    /// `navigate(to:)` with `.generator` and without a delegate does not present the generator screen.
    @MainActor
    func test_navigateTo_generator_withoutDelegate() throws {
        subject.navigate(to: .generator, context: nil)
        XCTAssertNil(stackNavigator.actions.last)
    }

    /// `navigate(to:)` with `.view` shows the view send screen.
    @MainActor
    func test_navigateTo_view() throws {
        let sendView = SendView.fixture()
        subject.navigate(to: .view(sendView))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? ViewSendItemView)
        XCTAssertEqual(view.store.state.sendView, sendView)
    }

    /// `navigate(to:)` with `.viewProfileSwitcher` opens the profile switcher.
    @MainActor
    func test_navigate_viewProfileSwitcher() throws {
        let handler = MockProfileSwitcherHandler()
        subject.navigate(to: .viewProfileSwitcher, context: handler)

        XCTAssertEqual(stackNavigator.actions.last?.type, .presented)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
    }

    /// `navigate(to:)` with `.viewProfileSwitcher` does not open the profile switcher if there isn't a handler.
    @MainActor
    func test_navigate_viewProfileSwitcher_noHandler() throws {
        subject.navigate(to: .viewProfileSwitcher, context: nil)

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }

    /// `handle(_:)` calls `handle(_:)` on the delegate.
    @MainActor
    func test_sendItemDelegate_handleAuthAction() async {
        let action = AuthAction.logout(userId: "1", userInitiated: true)
        await subject.handle(action)
        XCTAssertEqual(delegate.handledAuthActions, [action])
    }

    /// `sendItemCancelled()` dismisses the presented view.
    @MainActor
    func test_sendItemDelegate_sendItemCancelled() throws {
        subject.sendItemCancelled()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `sendItemCompleted(with:)` dismisses the view and presents the share sheet.
    @MainActor
    func test_sendItemDelegate_sendItemCompleted() throws {
        sendRepository.shareURLResult = .success(.example)

        subject.sendItemCompleted(with: .fixture())

        waitFor { stackNavigator.actions.count == 2 }

        XCTAssertEqual(stackNavigator.actions.count, 2)

        let shareAction = try XCTUnwrap(stackNavigator.actions[0])
        XCTAssertEqual(shareAction.type, .presented)
        XCTAssertTrue(shareAction.view is UIActivityViewController)

        let dismissAction = try XCTUnwrap(stackNavigator.actions[1])
        XCTAssertEqual(dismissAction.type, .dismissedWithCompletionHandler)
    }

    /// `sendItemCompleted(with:)` logs an error if generating the share URL fails.
    @MainActor
    func test_sendItemDelegate_sendItemCompleted_error() throws {
        sendRepository.shareURLResult = .failure(BitwardenTestError.example)

        subject.sendItemCompleted(with: .fixture())

        waitFor { !stackNavigator.actions.isEmpty }

        XCTAssertEqual(stackNavigator.actions.count, 1)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `sendItemCompleted(with:)` dismisses the view if the share URL is `nil`.
    @MainActor
    func test_sendItemDelegate_sendItemCompleted_nilURL() throws {
        sendRepository.shareURLResult = .success(nil)

        subject.sendItemCompleted(with: .fixture())

        waitFor { !stackNavigator.actions.isEmpty }

        XCTAssertEqual(stackNavigator.actions.count, 1)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

    /// `sendItemDeleted()` calls `sendItemDeleted()` on the delegate.
    @MainActor
    func test_sendItemDelegate_sendItemDeleted() {
        subject.sendItemDeleted()
        XCTAssertTrue(delegate.didSendItemDeleted)
    }
}
