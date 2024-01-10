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

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route.
    func test_receive_addItemPressed() {
        subject.receive(.addItemPressed)

        XCTAssertEqual(coordinator.routes.last, .addItem)
    }

    /// `receive(_:)` with `.searchTextChanged` updates the state correctly.
    func test_receive_searchTextChanged() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))

        XCTAssertEqual(subject.state.searchText, "search")
    }

    func test_receive_sendListItemRow_sendListItemPressed() {
        subject.receive(.sendListItemRow(.sendListItemPressed(.fixture())))

        // TODO: BIT-1389 Assert navigation to edit send route
    }
}
