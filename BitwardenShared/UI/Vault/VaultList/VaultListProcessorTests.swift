import XCTest

@testable import BitwardenShared

// MARK: - VaultListProcessorTests

class VaultListProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute>!
    var subject: VaultListProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        subject = VaultListProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: VaultListState()
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

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route.
    func test_receive_itemPressed() {
        subject.receive(.itemPressed(item: .fixture()))

        XCTAssertEqual(coordinator.routes.last, .viewItem)
    }

    /// `receive(_:)` with `.searchTextChanged` without a matching search term updates the state correctly.
    func test_receive_searchTextChanged_withoutResult() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))

        XCTAssertEqual(subject.state.searchText, "search")
        XCTAssertEqual(subject.state.searchResults.count, 0)
    }

    /// `receive(_:)` with `.searchTextChanged` with a matching search term updates the state correctly.
    func test_receive_searchTextChanged_withResult() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("example"))

        // TODO: BIT-628 Replace assertion with mock vault assertion
        XCTAssertEqual(subject.state.searchResults.count, 1)
    }
}
