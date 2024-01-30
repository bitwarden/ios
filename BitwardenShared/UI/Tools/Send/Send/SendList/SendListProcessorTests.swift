import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - SendListProcessorTests

class SendListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SendRoute, Void>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var sendRepository: MockSendRepository!
    var subject: SendListProcessor!

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        sendRepository = MockSendRepository()

        subject = SendListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                policyService: policyService,
                sendRepository: sendRepository
            ),
            state: SendListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        policyService = nil
        sendRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `loadData` loads the policy data for the view.
    func test_perform_loadData_policies() async {
        await subject.perform(.loadData)
        XCTAssertFalse(subject.state.isSendDisabled)

        policyService.policyAppliesToUserResult[.disableSend] = true
        await subject.perform(.loadData)
        XCTAssertTrue(subject.state.isSendDisabled)
    }

    /// `perform(_:)` with `refresh` calls the refresh method.
    func test_perform_refresh() async {
        await subject.perform(.refresh)

        XCTAssertTrue(sendRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `search(_:)` uses the send repository to perform a search and updates the
    /// state.
    func test_perform_search() async {
        subject.state.searchResults = []
        let sendListItem = SendListItem.fixture()
        sendRepository.searchSendSubject.send([sendListItem])

        await subject.perform(.search("for me"))

        XCTAssertEqual(subject.state.searchResults, [sendListItem])
    }

    /// `perform(_:)` with `sendListItemRow(copyLinkPressed())` uses the send repository to generate
    /// a url and copies it to the clipboard.
    func test_perform_sendListItemRow_copyLinkPressed() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.shareURLResult = .success(.example)
        await subject.perform(.sendListItemRow(.copyLinkPressed(sendView)))

        XCTAssertEqual(sendRepository.shareURLSendView, sendView)
        XCTAssertEqual(pasteboardService.copiedString, "https://example.com")
        XCTAssertEqual(
            subject.state.toast?.text,
            Localizations.valueHasBeenCopied(Localizations.sendLink)
        )
    }

    /// `perform(_:)` with `sendListItemRow(deletePressed())` uses the send repository to delete the
    /// send.
    func test_perform_sendListItemRow_deletePressed() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.deleteSendResult = .success(())
        await subject.perform(.sendListItemRow(.deletePressed(sendView)))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(sendRepository.deleteSendSendView, sendView)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.deleting)
        XCTAssertEqual(subject.state.toast?.text, Localizations.sendDeleted)
    }

    /// `perform(_:)` with `sendListItemRow(removePassword())` uses the send repository to remove
    /// the password from a send.
    func test_perform_sendListItemRow_deletePressed_networkError() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.deleteSendResult = .failure(URLError(.timedOut))
        await subject.perform(.sendListItemRow(.deletePressed(sendView)))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(sendRepository.deleteSendSendView, sendView)

        sendRepository.deleteSendResult = .success(())
        let errorAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await errorAlert.tapAction(title: Localizations.tryAgain)

        XCTAssertEqual(
            coordinator.loadingOverlaysShown.last?.title,
            Localizations.deleting
        )
        XCTAssertEqual(subject.state.toast?.text, Localizations.sendDeleted)
    }

    /// `perform(_:)` with `sendListItemRow(removePassword())` uses the send repository to remove
    /// the password from a send.
    func test_perform_sendListItemRow_removePassword_success() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.removePasswordFromSendResult = .success(sendView)
        await subject.perform(.sendListItemRow(.removePassword(sendView)))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(sendRepository.removePasswordFromSendSendView, sendView)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown.last?.title,
            Localizations.removingSendPassword
        )
        XCTAssertEqual(subject.state.toast?.text, Localizations.sendPasswordRemoved)
    }

    /// `perform(_:)` with `sendListItemRow(removePassword())` uses the send repository to remove
    /// the password from a send.
    func test_perform_sendListItemRow_removePassword_networkError() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.removePasswordFromSendResult = .failure(URLError(.timedOut))
        await subject.perform(.sendListItemRow(.removePassword(sendView)))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(sendRepository.removePasswordFromSendSendView, sendView)

        sendRepository.removePasswordFromSendResult = .success(sendView)
        let errorAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await errorAlert.tapAction(title: Localizations.tryAgain)

        XCTAssertEqual(
            coordinator.loadingOverlaysShown.last?.title,
            Localizations.removingSendPassword
        )
        XCTAssertEqual(subject.state.toast?.text, Localizations.sendPasswordRemoved)
    }

    /// `perform(_:)` with `sendListItemRow(shareLinkPressed())` uses the send repository to generate
    /// a url and navigates to the `.share` route.
    func test_perform_sendListItemRow_shareLinkPressed() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.shareURLResult = .success(.example)
        await subject.perform(.sendListItemRow(.shareLinkPressed(sendView)))

        XCTAssertEqual(sendRepository.shareURLSendView, sendView)
        XCTAssertEqual(coordinator.routes.last, .share(url: .example))
    }

    /// `perform(_:)` with `.streamSendList` updates the state's send list whenever it changes.
    func test_perform_streamSendList() {
        let sendListItem = SendListItem(id: "1", itemType: .group(.file, 42))
        sendRepository.sendListSubject.send([
            SendListSection(id: "1", isCountDisplayed: true, items: [sendListItem], name: "Name"),
        ])

        let task = Task {
            await subject.perform(.streamSendList)
        }

        waitFor(!subject.state.sections.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.sections.count, 1)
        XCTAssertEqual(subject.state.sections[0].items, [sendListItem])
    }

    /// `perform(_:)` with `.streamSendList` records any errors.
    func test_perform_streamSendList_error() {
        sendRepository.sendListSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.streamSendList)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route.
    func test_receive_addItemPressed() {
        subject.receive(.addItemPressed)

        XCTAssertEqual(coordinator.routes.last, .addItem)
    }

    /// `receive(_:)` with `.clearInfoUrl` clears the info url.
    func test_receive_clearInfoUrl() {
        subject.state.infoUrl = .example
        subject.receive(.clearInfoUrl)

        XCTAssertNil(subject.state.infoUrl)
    }

    /// `receive(_:)` with `.infoButtonPressed` sets the info url.
    func test_receive_infoButtonPressed() {
        subject.state.infoUrl = nil
        subject.receive(.infoButtonPressed)

        XCTAssertEqual(subject.state.infoUrl, ExternalLinksConstants.sendInfo)
    }

    /// `receive(_:)` with `.searchTextChanged` updates the state correctly.
    func test_receive_searchTextChanged() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))

        XCTAssertEqual(subject.state.searchText, "search")
    }

    /// `receive(_:)` with `.sendListItemRow(.editPressed())` navigates to the edit send route.
    func test_receive_sendListItemRow_editPressed() {
        let sendView = SendView.fixture()
        subject.receive(.sendListItemRow(.editPressed(sendView)))

        XCTAssertEqual(coordinator.routes.last, .editItem(sendView))
    }

    /// `receive(_:)` with `.sendListItemRow(.sendListItemPressed())` navigates to the edit send route.
    func test_receive_sendListItemRow_sendListItemPressed_withSendView() {
        let sendView = SendView.fixture()
        let item = SendListItem(sendView: sendView)!
        subject.receive(.sendListItemRow(.sendListItemPressed(item)))

        XCTAssertEqual(coordinator.routes.last, .editItem(sendView))
    }

    /// `receive(_:)` with `.sendListItemRow(.sendListItemPressed())` navigates to the group send route.
    func test_receive_sendListItemRow_sendListItemPressed_withGroup() {
        let item = SendListItem.groupFixture()
        subject.receive(.sendListItemRow(.sendListItemPressed(item)))

        // TODO: BIT-1412 Assert navigation to group send route
    }

    /// `receive(_:)` with `.toastShown` updates the toast value in the state.
    func test_receive_toastShown() {
        subject.state.toast = Toast(text: "toasty")
        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `sendItemCancelled()` navigates to the `.dismiss` route.
    func test_sendItemCancelled() {
        subject.sendItemCancelled()

        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `sendItemCompleted()` navigates to the `.dismiss` route and then routes to the share screen.
    func test_sendItemCompleted() throws {
        sendRepository.shareURLResult = .success(.example)
        let sendView = SendView.fixture()
        subject.sendItemCompleted(with: sendView)

        waitFor(
            sendRepository.shareURLSendView != nil && !coordinator.routes.isEmpty
        )

        XCTAssertEqual(sendRepository.shareURLSendView, sendView)
        XCTAssertEqual(coordinator.routes.count, 1)

        switch coordinator.routes[0] {
        case let .dismiss(dismissAction):
            let action = try XCTUnwrap(dismissAction?.action)
            action()
        default:
            XCTFail("The route was not a dismiss route: \(coordinator.routes[0])")
        }
        XCTAssertEqual(coordinator.routes.last, .share(url: .example))
    }

    /// `.sendItemDeleted()` shows a toast with the send deleted message.
    func test_sendItemDeleted() {
        subject.sendItemDeleted()
        XCTAssertEqual(subject.state.toast?.text, Localizations.sendDeleted)
    }
}
