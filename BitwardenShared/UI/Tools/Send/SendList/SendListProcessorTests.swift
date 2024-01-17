import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - SendListProcessorTests

class SendListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SendRoute>!
    var sendRepository: MockSendRepository!
    var subject: SendListProcessor!

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        sendRepository = MockSendRepository()
        subject = SendListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(sendRepository: sendRepository),
            state: SendListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
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

    func test_perform_refresh() async {
        await subject.perform(.refresh)

        XCTAssertTrue(sendRepository.fetchSyncCalled)
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

    func test_receive_sendListItemRow_sendListItemPressed_withSendView() {
        let sendView = SendView.fixture()
        let item = SendListItem(sendView: sendView)!
        subject.receive(.sendListItemRow(.sendListItemPressed(item)))

        XCTAssertEqual(coordinator.routes.last, .edit(sendView))
    }

    func test_receive_sendListItemRow_sendListItemPressed_withGroup() {
        let item = SendListItem.groupFixture()
        subject.receive(.sendListItemRow(.sendListItemPressed(item)))

        // TODO: BIT-1412 Assert navigation to group send route
    }
}
