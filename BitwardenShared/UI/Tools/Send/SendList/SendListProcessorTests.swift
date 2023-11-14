import XCTest

@testable import BitwardenShared

// MARK: - SendListProcessorTests

class SendListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SendRoute>!
    var subject: SendListProcessor!

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        subject = SendListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: SendListState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

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
}
