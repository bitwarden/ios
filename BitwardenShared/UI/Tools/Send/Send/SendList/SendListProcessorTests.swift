import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

// MARK: - SendListProcessorTests

class SendListProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var coordinator: MockCoordinator<SendRoute, Void>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var policyService: MockPolicyService!
    var sendRepository: MockSendRepository!
    var subject: SendListProcessor!
    var vaultRepository: MockVaultRepository!

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        policyService = MockPolicyService()
        sendRepository = MockSendRepository()
        vaultRepository = MockVaultRepository()

        subject = SendListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                policyService: policyService,
                sendRepository: sendRepository,
                vaultRepository: vaultRepository
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
        vaultRepository = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.addItemPressed` navigates to the `.addItem` route.
    @MainActor
    func test_perform_addItemPressed_fileType() async {
        subject.state.type = .file
        await subject.perform(.addItemPressed(.file))

        XCTAssertEqual(coordinator.routes.last, .addItem(type: .file))
    }

    /// `perform(_:)` with `.addItemPressed` shows an alert if attempting to add a file send and
    /// the user doesn't have premium.
    @MainActor
    func test_perform_addItemPressed_fileType_withoutPremium() async throws {
        sendRepository.doesActivateAccountHavePremiumResult = false
        subject.state.type = .file
        await subject.perform(.addItemPressed(.file))

        XCTAssertEqual(
            coordinator.alertShown,
            [.defaultAlert(title: Localizations.sendFilePremiumRequired)]
        )
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.addItemPressed` navigates to the `.addItem` route.
    @MainActor
    func test_perform_addItemPressed_textType() async {
        subject.state.type = .text
        await subject.perform(.addItemPressed(.text))

        XCTAssertEqual(coordinator.routes.last, .addItem(type: .text))
    }

    /// `perform(_:)` with `loadData` loads the policy data for the view.
    @MainActor
    func test_perform_loadData_policies() async {
        await subject.perform(.loadData)
        XCTAssertFalse(subject.state.isSendDisabled)

        policyService.policyAppliesToUserResult[.disableSend] = true
        await subject.perform(.loadData)
        XCTAssertTrue(subject.state.isSendDisabled)
    }

    /// `perform(_:)` with `refresh` requests a fetch sync update, but does not force a sync.
    func test_perform_refresh() async {
        await subject.perform(.refresh)

        XCTAssertTrue(sendRepository.fetchSyncCalled)
        XCTAssertFalse(try XCTUnwrap(sendRepository.fetchSyncIsPeriodic))
        XCTAssertEqual(sendRepository.fetchSyncForceSync, false)
    }

    /// `perform(_:)` with `search(_:)` and an empty search query returns early.
    @MainActor
    func test_perform_search_empty() async {
        subject.state.searchResults = []

        await subject.perform(.search("  "))

        XCTAssertNil(sendRepository.searchSendSearchText)
        XCTAssertNil(sendRepository.searchSendType)
    }

    /// `perform(_:)` with `search(_:)` displays an alert and logs an error if one occurs.
    @MainActor
    func test_perform_search_error() {
        subject.state.searchResults = []

        sendRepository.searchSendSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.search("send"))
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `search(_:)` uses the send repository to perform a search and updates the
    /// state.
    @MainActor
    func test_perform_search_nilType() {
        subject.state.type = nil
        subject.state.searchResults = []
        let sendListItem = SendListItem.fixture()
        sendRepository.searchSendSubject.send([sendListItem])

        let task = Task {
            await subject.perform(.search("for me"))
        }
        waitFor(!subject.state.searchResults.isEmpty)
        task.cancel()

        XCTAssertEqual(sendRepository.searchSendSearchText, "for me")
        XCTAssertNil(sendRepository.searchSendType)
        XCTAssertEqual(subject.state.searchResults, [sendListItem])
    }

    /// `perform(_:)` with `search(_:)` uses the send repository to perform a search and subscribes
    /// to the results in case they update.
    @MainActor
    func test_perform_search_subscribesToResults() {
        subject.state.searchResults = []

        let item1 = SendListItem.fixture(sendView: .fixture(id: "1"))
        let item2 = SendListItem.fixture(sendView: .fixture(id: "1"))

        let task = Task {
            await subject.perform(.search("test"))
        }

        sendRepository.searchSendSubject.send([item1])
        waitFor(subject.state.searchResults == [item1])

        sendRepository.searchSendSubject.send([item2])
        waitFor(subject.state.searchResults == [item2])
        task.cancel()

        XCTAssertEqual(sendRepository.searchSendSearchText, "test")
        XCTAssertNil(sendRepository.searchSendType)
        XCTAssertEqual(subject.state.searchResults, [item2])
    }

    /// `perform(_:)` with `search(_:)` uses the send repository to perform a search and updates the
    /// state.
    @MainActor
    func test_perform_search_textType() {
        subject.state.type = .text
        subject.state.searchResults = []
        let sendListItem = SendListItem.fixture()
        sendRepository.searchSendSubject.send([sendListItem])

        let task = Task {
            await subject.perform(.search("for me"))
        }
        waitFor(!subject.state.searchResults.isEmpty)
        task.cancel()

        XCTAssertEqual(sendRepository.searchSendSearchText, "for me")
        XCTAssertEqual(sendRepository.searchSendType, .text)
        XCTAssertEqual(subject.state.searchResults, [sendListItem])
    }

    /// `perform(_:)` with `sendListItemRow(copyLinkPressed())` uses the send repository to generate
    /// a url and copies it to the clipboard.
    @MainActor
    func test_perform_sendListItemRow_copyLinkPressed() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.shareURLResult = .success(.example)
        await subject.perform(.sendListItemRow(.copyLinkPressed(sendView)))

        XCTAssertEqual(sendRepository.shareURLSendView, sendView)
        XCTAssertEqual(pasteboardService.copiedString, "https://example.com")
        XCTAssertEqual(
            subject.state.toast,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.sendLink))
        )
    }

    /// `perform(_:)` with `sendListItemRow(deletePressed())` uses the send repository to delete the
    /// send.
    @MainActor
    func test_perform_sendListItemRow_deletePressed() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.deleteSendResult = .success(())
        await subject.perform(.sendListItemRow(.deletePressed(sendView)))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.delete)

        XCTAssertEqual(sendRepository.deleteSendSendView, sendView)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.deleting)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.sendDeleted))
    }

    /// `perform(_:)` with `sendListItemRow(removePassword())` uses the send repository to remove
    /// the password from a send.
    @MainActor
    func test_perform_sendListItemRow_deletePressed_networkError() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        let error = URLError(.timedOut)
        sendRepository.deleteSendResult = .failure(error)
        await subject.perform(.sendListItemRow(.deletePressed(sendView)))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.delete)

        XCTAssertEqual(sendRepository.deleteSendSendView, sendView)

        sendRepository.deleteSendResult = .success(())
        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? URLError, error)
        await errorAlertWithRetry.retry()

        XCTAssertEqual(
            coordinator.loadingOverlaysShown.last?.title,
            Localizations.deleting
        )
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.sendDeleted))
    }

    /// `perform(_:)` with `sendListItemRow(removePassword())` uses the send repository to remove
    /// the password from a send.
    @MainActor
    func test_perform_sendListItemRow_removePassword_success() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.removePasswordFromSendResult = .success(sendView)
        await subject.perform(.sendListItemRow(.removePassword(sendView)))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.remove)

        XCTAssertEqual(sendRepository.removePasswordFromSendSendView, sendView)
        XCTAssertEqual(
            coordinator.loadingOverlaysShown.last?.title,
            Localizations.removingSendPassword
        )
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.sendPasswordRemoved))
    }

    /// `perform(_:)` with `sendListItemRow(removePassword())` uses the send repository to remove
    /// the password from a send.
    @MainActor
    func test_perform_sendListItemRow_removePassword_networkError() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        let error = URLError(.timedOut)
        sendRepository.removePasswordFromSendResult = .failure(error)
        await subject.perform(.sendListItemRow(.removePassword(sendView)))

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.remove)

        XCTAssertEqual(sendRepository.removePasswordFromSendSendView, sendView)

        sendRepository.removePasswordFromSendResult = .success(sendView)
        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? URLError, error)
        await errorAlertWithRetry.retry()

        XCTAssertEqual(
            coordinator.loadingOverlaysShown.last?.title,
            Localizations.removingSendPassword
        )
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.sendPasswordRemoved))
    }

    /// `perform(_:)` with `sendListItemRow(shareLinkPressed())` uses the send repository to generate
    /// a url and navigates to the `.share` route.
    @MainActor
    func test_perform_sendListItemRow_shareLinkPressed() async throws {
        let sendView = SendView.fixture(id: "SEND_ID")
        sendRepository.shareURLResult = .success(.example)
        await subject.perform(.sendListItemRow(.shareLinkPressed(sendView)))

        XCTAssertEqual(sendRepository.shareURLSendView, sendView)
        XCTAssertEqual(coordinator.routes.last, .share(url: .example))
    }

    /// `perform(_:)` with `.streamSendList` updates the state's send list whenever it changes.
    @MainActor
    func test_perform_streamSendList_nilType() throws {
        let sendListItem = SendListItem(id: "1", itemType: .group(.file, 42))
        sendRepository.sendListSubject.send([
            SendListSection(id: "1", items: [sendListItem], name: "Name"),
        ])

        let task = Task {
            await subject.perform(.streamSendList)
        }

        waitFor(subject.state.loadingState.data != nil)
        task.cancel()

        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items, [sendListItem])
    }

    /// `perform(_:)` with `.streamSendList` records any errors.
    func test_perform_streamSendList_nilType_error() {
        sendRepository.sendListSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.streamSendList)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `.streamSendList` updates the state's send list whenever it changes,
    /// syncing first if a sync is needed and the vault is empty.
    @MainActor
    func test_perform_streamSendList_nilType_needsSync() throws {
        let sendListItem = SendListItem(id: "1", itemType: .group(.file, 42))
        sendRepository.fetchSyncHandler = { [weak self] in
            guard let self else { return }
            // Update `sendListSubject` after `fetchSync` is called to simulate an initially empty
            // vault, syncing, and then sends in the list.
            sendRepository.sendListSubject.send([
                SendListSection(id: "1", items: [sendListItem], name: "Name"),
            ])
        }
        vaultRepository.needsSyncResult = .success(true)

        let task = Task {
            await subject.perform(.streamSendList)
        }

        waitFor(subject.state.loadingState.data?.count == 1)
        task.cancel()

        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items, [sendListItem])
        XCTAssertTrue(vaultRepository.needsSyncCalled)
    }

    /// `perform(_:)` with `.streamSendList` logs an error if sync is needed but it fails, but still
    /// receives any updates from the publisher if the send list changes.
    @MainActor
    func test_perform_streamSendList_nilType_needsSync_error() throws {
        sendRepository.fetchSyncResult = .failure(BitwardenTestError.example)
        vaultRepository.needsSyncResult = .success(true)

        let task = Task {
            await subject.perform(.streamSendList)
        }

        waitFor(!errorReporter.errors.isEmpty)

        let sendListItem = SendListItem(id: "1", itemType: .group(.file, 42))
        sendRepository.sendListSubject.send([
            SendListSection(id: "1", items: [sendListItem], name: "Name"),
        ])

        waitFor(subject.state.loadingState.data?.count == 1)
        task.cancel()

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items, [sendListItem])
        XCTAssertTrue(vaultRepository.needsSyncCalled)
    }

    /// `perform(_:)` with `.streamSendList` updates the state's send list whenever it changes.
    @MainActor
    func test_perform_streamSendList_textType() throws {
        let sendListItem = SendListItem.fixture()
        sendRepository.sendTypeListSubject.send([
            sendListItem,
        ])

        subject.state.type = .text

        let task = Task {
            await subject.perform(.streamSendList)
        }

        waitFor(subject.state.loadingState.data != nil)
        task.cancel()

        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertEqual(sendRepository.sendTypeListPublisherType, .text)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items, [sendListItem])
    }

    /// `perform(_:)` with `.streamSendList` updates the state's send list whenever it changes.
    @MainActor
    func test_perform_streamSendList_textType_empty() throws {
        subject.state.type = .text

        let task = Task {
            await subject.perform(.streamSendList)
        }

        waitFor(subject.state.loadingState.data != nil)
        task.cancel()

        let sections = try XCTUnwrap(subject.state.loadingState.data)
        XCTAssertTrue(sections.isEmpty)
    }

    /// `receive(_:)` with `.clearInfoUrl` clears the info url.
    @MainActor
    func test_receive_clearInfoUrl() {
        subject.state.infoUrl = .example
        subject.receive(.clearInfoUrl)

        XCTAssertNil(subject.state.infoUrl)
    }

    /// `receive(_:)` with `.infoButtonPressed` sets the info url.
    @MainActor
    func test_receive_infoButtonPressed() {
        subject.state.infoUrl = nil
        subject.receive(.infoButtonPressed)

        XCTAssertEqual(subject.state.infoUrl, ExternalLinksConstants.sendInfo)
    }

    /// `receive(_:)` with `.searchTextChanged` updates the state correctly.
    @MainActor
    func test_receive_searchTextChanged() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))

        XCTAssertEqual(subject.state.searchText, "search")
    }

    /// `receive(_:)` with `.sendListItemRow(.editPressed())` navigates to the edit send route.
    @MainActor
    func test_receive_sendListItemRow_editPressed() {
        let sendView = SendView.fixture()
        subject.receive(.sendListItemRow(.editPressed(sendView)))

        XCTAssertEqual(coordinator.routes.last, .editItem(sendView))
    }

    /// `receive(_:)` with `.sendListItemRow(.sendListItemPressed())` navigates to the view send route.
    @MainActor
    func test_receive_sendListItemRow_sendListItemPressed_withSendView() {
        let sendView = SendView.fixture()
        let item = SendListItem(sendView: sendView)!
        subject.receive(.sendListItemRow(.sendListItemPressed(item)))

        XCTAssertEqual(coordinator.routes.last, .viewItem(sendView))
    }

    /// `receive(_:)` with `.sendListItemRow(.sendListItemPressed())` navigates to the group send route.
    @MainActor
    func test_receive_sendListItemRow_sendListItemPressed_withGroup() {
        let item = SendListItem.groupFixture(sendType: .file)
        subject.receive(.sendListItemRow(.sendListItemPressed(item)))

        XCTAssertEqual(coordinator.routes.last, .group(.file))
    }

    /// `receive(_:)` with `.sendListItemRow(.viewSend())` navigates to the view send route.
    @MainActor
    func test_receive_sendListItemRow_viewSend() {
        let sendView = SendView.fixture()
        subject.receive(.sendListItemRow(.viewSend(sendView)))

        XCTAssertEqual(coordinator.routes.last, .viewItem(sendView))
    }

    /// `receive(_:)` with `.toastShown` updates the toast value in the state.
    @MainActor
    func test_receive_toastShown() {
        subject.state.toast = Toast(title: "toasty")
        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `sendItemCancelled()` navigates to the `.dismiss` route.
    @MainActor
    func test_sendItemCancelled() {
        subject.sendItemCancelled()

        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }

    /// `sendItemCompleted()` navigates to the `.dismiss` route and then routes to the share screen.
    @MainActor
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
    @MainActor
    func test_sendItemDeleted() {
        subject.sendItemDeleted()
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.sendDeleted))
    }
}
