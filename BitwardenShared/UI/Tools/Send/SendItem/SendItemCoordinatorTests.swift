import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - SendItemCoordinatorTests

class SendItemCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockSendItemDelegate!
    var module: MockAppModule!
    var sendRepository: MockSendRepository!
    var stackNavigator: MockStackNavigator!
    var subject: SendItemCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        delegate = MockSendItemDelegate()
        module = MockAppModule()
        sendRepository = MockSendRepository()
        stackNavigator = MockStackNavigator()
        subject = SendItemCoordinator(
            delegate: delegate,
            module: module,
            services: ServiceContainer.withMocks(sendRepository: sendRepository),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        delegate = nil
        module = nil
        sendRepository = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.add()` shows the add item screen.
    func test_navigateTo_add_noContent_hasPremium() throws {
        subject.navigate(to: .add(content: nil, hasPremium: true))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertTrue(view.store.state.hasPremium)
        XCTAssertEqual(view.store.state.mode, .add)
    }

    /// `navigate(to:)` with `.addItem` shows the add send item screen.
    func test_navigateTo_add_noContent_notHasPremium() throws {
        subject.navigate(to: .add(content: nil, hasPremium: false))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertFalse(view.store.state.hasPremium)
        XCTAssertEqual(view.store.state.mode, .add)
    }

    /// `navigate(to:)` with `.add()` shows the add item screen with prefilled text content.
    func test_navigateTo_add_textContent() throws {
        subject.navigate(to: .add(content: .text("test"), hasPremium: true))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertTrue(view.store.state.hasPremium)
        XCTAssertEqual(view.store.state.mode, .shareExtension)
        XCTAssertEqual(view.store.state.type, .text)
        XCTAssertEqual(view.store.state.text, "test")
        XCTAssertNil(view.store.state.fileName)
        XCTAssertNil(view.store.state.fileData)
    }

    /// `navigate(to:)` with `.add()` shows the add send item screen with prefilled text content.
    func test_navigateTo_add_fileContent() throws {
        subject.navigate(
            to: .add(
                content: .file(
                    fileName: "test file",
                    fileData: Data("test data".utf8)
                ),
                hasPremium: false
            )
        )

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertFalse(view.store.state.hasPremium)
        XCTAssertEqual(view.store.state.mode, .shareExtension)
        XCTAssertEqual(view.store.state.type, .file)
        XCTAssertEqual(view.store.state.text, "")
        XCTAssertEqual(view.store.state.fileName, "test file")
        XCTAssertEqual(view.store.state.fileData, Data("test data".utf8))
    }

    /// `navigate(to:)` with `.cancel` notifies the delegate.
    func test_navigateTo_cancel() {
        subject.navigate(to: .cancel)

        XCTAssertTrue(delegate.didSendItemCancelled)
    }

    /// `navigate(to:)` with `.complete` notifies the delegate.
    func test_navigateTo_complete() {
        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        subject.navigate(to: .complete(sendView))

        XCTAssertTrue(delegate.didSendItemCompleted)
        XCTAssertEqual(delegate.sendItemCompletedSendView, sendView)
    }

    /// `navigate(to:)` with `.edit` shows the edit screen.
    func test_navigateTo_edit_hasPremium() throws {
        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        subject.navigate(to: .edit(sendView, hasPremium: true))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertTrue(view.store.state.hasPremium)
        XCTAssertEqual(view.store.state.name, "Name")
        XCTAssertEqual(view.store.state.mode, .edit)
    }

    /// `navigate(to:)` with `.edit` shows the edit screen.
    func test_navigateTo_edit_notHasPremium() throws {
        let sendView = SendView.fixture(id: "SEND_ID", name: "Name")
        subject.navigate(to: .edit(sendView, hasPremium: false))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        let view = try XCTUnwrap(action.view as? AddEditSendItemView)
        XCTAssertFalse(view.store.state.hasPremium)
        XCTAssertEqual(view.store.state.name, "Name")
        XCTAssertEqual(view.store.state.mode, .edit)
    }

    /// `navigate(to:)` with `.fileSelection` and with a file selection delegate presents the file
    /// selection screen.
    func test_navigateTo_fileSelection_withDelegate() throws {
        let delegate = MockFileSelectionDelegate()
        subject.navigate(to: .fileSelection(.camera), context: delegate)

        XCTAssertEqual(module.fileSelectionCoordinator.routes.last, .camera)
        XCTAssertTrue(module.fileSelectionCoordinator.isStarted)
        XCTAssertIdentical(module.fileSelectionDelegate, delegate)
    }

    /// `navigate(to:)` with `.fileSelection` and without a file selection delegate does not present the
    /// file selection screen.
    func test_navigateTo_fileSelection_withoutDelegate() throws {
        subject.navigate(to: .fileSelection(.camera), context: nil)
        XCTAssertNil(stackNavigator.actions.last)
    }
}
