import XCTest

@testable import BitwardenShared

// MARK: - SendListProcessorTests

class SendListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SendRoute>!
    var errorReporter: MockErrorReporter!
    var sendRepository: MockSendRepository!
    var subject: SendListProcessor!

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        sendRepository = MockSendRepository()

        subject = SendListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                sendRepository: sendRepository
            ),
            state: SendListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        sendRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` updates the state's send list whenever it changes.
    func test_perform_appeared() {
        let sendListItem = SendListItem(id: "1", itemType: .group(.file, 42))
        sendRepository.sendListSubject.send([
            SendListSection(id: "1", isCountDisplayed: true, items: [sendListItem], name: "Name"),
        ])

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!subject.state.sections.isEmpty)
        task.cancel()

        XCTAssertEqual(subject.state.sections.count, 1)
        XCTAssertEqual(subject.state.sections[0].items, [sendListItem])
    }

    /// `perform(_:)` with `.appeared` records any errors.
    func test_perform_appeared_error() {
        sendRepository.sendListSubject.send(completion: .failure(BitwardenTestError.example))

        let task = Task {
            await subject.perform(.appeared)
        }

        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(_:)` with `refresh` calls the refresh method.
    func test_perform_refresh() async {
        await subject.perform(.refresh)

        XCTAssertTrue(sendRepository.fetchSyncCalled)
    }

    /// `perform(_:)` with `refresh` records any errors.
    func test_perform_refresh_error() async {
        sendRepository.fetchSyncResult = .failure(BitwardenTestError.example)

        await subject.perform(.refresh)

        XCTAssertTrue(sendRepository.fetchSyncCalled)
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

    /// `receive(_:)` with `.sendListItemRow(.sendListItemPressed())` navigates to the edit send route.
    func test_receive_sendListItemRow_sendListItemPressed() {
        subject.receive(.sendListItemRow(.sendListItemPressed(.fixture())))

        // TODO: BIT-1389 Assert navigation to edit send route
    }
}
