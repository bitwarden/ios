import XCTest

@testable import BitwardenShared

// MARK: - VaultGroupProcessorTests

class VaultGroupProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute>!
    var subject: VaultGroupProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        subject = VaultGroupProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: VaultGroupState()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` starts streaming vault items.
    func test_perform_appeared() async {
        await subject.perform(.appeared)
        // TODO: BIT-374 Assert that the vault repository is hooked up properly
    }

    /// `receive(_:)` with `.addItemPressed` navigates to the `.addItem` route with the correct group.
    func test_receive_addItemPressed() {
        subject.state.group = .card
        subject.receive(.addItemPressed)
        XCTAssertEqual(coordinator.routes.last, .addItem(group: .card))
    }

    /// `receive(_:)` with `.itemPressed` navigates to the `.viewItem` route.
    func test_receive_itemPressed() {
        subject.receive(.itemPressed(.fixture()))
        XCTAssertEqual(coordinator.routes.last, .viewItem)
    }

    /// `receive(_:)` with `.morePressed` navigates to the more menu.
    func test_receive_morePressed() {
        subject.receive(.morePressed(.fixture()))
        // TODO: BIT-375 Assert navigation to the more menu
    }

    /// `receive(_:)` with `.searchTextChanged` and no value sets the state correctly.
    func test_receive_searchTextChanged_withoutValue() {
        subject.state.searchText = "search"
        subject.receive(.searchTextChanged(""))
        XCTAssertEqual(subject.state.searchText, "")
    }

    /// `receive(_:)` with `.searchTextChanged` and a value sets the state correctly.
    func test_receive_searchTextChanged_withValue() {
        subject.state.searchText = ""
        subject.receive(.searchTextChanged("search"))
        XCTAssertEqual(subject.state.searchText, "search")
    }
}
