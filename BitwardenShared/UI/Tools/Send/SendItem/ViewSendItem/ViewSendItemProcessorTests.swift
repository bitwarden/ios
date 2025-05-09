import BitwardenKitMocks
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
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
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
}
