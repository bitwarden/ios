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
                    fileData: Data("test data".utf8)
                )
            )
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
            .shareExtension(.empty())
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
}
