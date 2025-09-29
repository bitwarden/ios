import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

class ViewSendItemProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SendItemRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var sendRepository: MockSendRepository!
    var subject: ViewSendItemProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        sendRepository = MockSendRepository()

        subject = ViewSendItemProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                sendRepository: sendRepository
            ),
            state: ViewSendItemState(sendView: .fixture())
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        sendRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `deleteSend` shows a confirmation alert and then uses the send repository
    /// to delete the send.
    @MainActor
    func test_perform_deleteSend() async throws {
        let sendView = SendView.fixture()
        subject.state = ViewSendItemState(sendView: sendView)
        sendRepository.deleteSendResult = .success(())

        await subject.perform(.deleteSend)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .confirmationDestructive(title: Localizations.areYouSureDeleteSend) {})

        try await alert.tapCancel()
        XCTAssertNil(sendRepository.deleteSendSendView)

        try await alert.tapAction(title: Localizations.delete)
        XCTAssertEqual(sendRepository.deleteSendSendView, sendView)
        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.deleting)
        XCTAssertEqual(coordinator.routes.last, .deleted)
    }

    /// `perform(_:)` with `deleteSend` shows an error alert and logs an error if an error occurs
    /// when deleting the send.
    @MainActor
    func test_perform_deleteSend_error() async throws {
        let sendView = SendView.fixture()
        subject.state = ViewSendItemState(sendView: sendView)
        sendRepository.deleteSendResult = .failure(BitwardenTestError.example)

        await subject.perform(.deleteSend)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.delete)

        sendRepository.deleteSendResult = .success(())
        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? BitwardenTestError, .example)
        await errorAlertWithRetry.retry()

        XCTAssertEqual(coordinator.loadingOverlaysShown.last?.title, Localizations.deleting)
        XCTAssertEqual(coordinator.routes.last, .deleted)
    }

    /// `perform(_:)` with `loadData` loads the share URL for the view.
    @MainActor
    func test_perform_loadData_shareURL() async {
        sendRepository.shareURLResult = .success(.example)
        await subject.perform(.loadData)
        XCTAssertEqual(subject.state.shareURL, .example)
    }

    /// `perform(_:)` with `loadData` logs an error if one occurs.
    @MainActor
    func test_perform_loadData_shareURL_error() async {
        sendRepository.shareURLResult = .failure(BitwardenTestError.example)
        await subject.perform(.loadData)
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `loadData` updates the state with any new updates to the send.
    @MainActor
    func test_perform_streamSend() async throws {
        let task = Task {
            await subject.perform(.streamSend)
        }
        defer { task.cancel() }

        let updatedSendView = SendView.fixture(name: "Updated Send")
        sendRepository.sendSubject.send(updatedSendView)

        try await waitForAsync { self.subject.state.sendView == updatedSendView }
        XCTAssertEqual(subject.state.sendView, updatedSendView)
    }

    /// `perform(_:)` with `loadData` logs an error if one occurs streaming the send.
    @MainActor
    func test_perform_streamSend_error() async throws {
        sendRepository.sendSubject.send(completion: .failure(BitwardenTestError.example))

        await subject.perform(.streamSend)

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `loadData` logs an error if the send has a `nil` ID.
    @MainActor
    func test_perform_streamSend_sendIdNil() async throws {
        subject.state.sendView = .fixture(id: nil)

        await subject.perform(.streamSend)

        let errorMessage = "View Send: send ID is nil, can't stream updates to send"
        XCTAssertEqual((errorReporter.errors.last as? NSError)?.domain, "Data Error")
        XCTAssertEqual((errorReporter.errors.last as? NSError)?.userInfo["ErrorMessage"] as? String, errorMessage)
        XCTAssertEqual((coordinator.errorAlertsShown.last as? NSError)?.domain, "Data Error")
        XCTAssertEqual(
            (coordinator.errorAlertsShown.last as? NSError)?.userInfo["ErrorMessage"] as? String,
            errorMessage
        )
    }

    /// `receive(_:)` with `.copyNotes` copies the send's notes and displays a toast.
    @MainActor
    func test_receive_copyNotes() {
        let notes = "Notes for my send"
        subject.state = ViewSendItemState(sendView: .fixture(notes: notes))

        subject.receive(.copyNotes)

        XCTAssertEqual(pasteboardService.copiedString, notes)
        XCTAssertEqual(
            subject.state.toast,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.privateNote))
        )
    }

    /// `receive(_:)` with `.copyShareURL` copies the URL and displays a toast.
    @MainActor
    func test_receive_copyShareURL() {
        subject.state.shareURL = .example

        subject.receive(.copyShareURL)

        XCTAssertEqual(pasteboardService.copiedString, URL.example.absoluteString)
        XCTAssertEqual(
            subject.state.toast,
            Toast(title: Localizations.valueHasBeenCopied(Localizations.sendLink))
        )
    }

    /// `receive(_:)` with `.dismiss` navigates to the cancel route.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .cancel)
    }

    /// `receive(_:)` with `.editItem` navigates to the edit send view.
    @MainActor
    func test_receive_editItem() {
        subject.receive(.editItem)

        XCTAssertEqual(coordinator.routes.last, .edit(subject.state.sendView))
    }

    /// `receive(_:)` with `.shareSend` navigates to the share route.
    @MainActor
    func test_receive_shareSend() {
        subject.state.shareURL = .example
        subject.receive(.shareSend)
        XCTAssertEqual(coordinator.routes.last, .share(url: .example))
    }

    /// `receive(_:)` with `.toastShown` updates the toast value in the state.
    @MainActor
    func test_receive_toastShown() {
        subject.state.toast = Toast(title: "toasty")
        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `.toggleAdditionalOptions` toggles whether the additional options are expanded.
    @MainActor
    func test_receive_toggleAdditionalOptions() {
        subject.receive(.toggleAdditionalOptions)
        XCTAssertTrue(subject.state.isAdditionalOptionsExpanded)

        subject.receive(.toggleAdditionalOptions)
        XCTAssertFalse(subject.state.isAdditionalOptionsExpanded)
    }
}
