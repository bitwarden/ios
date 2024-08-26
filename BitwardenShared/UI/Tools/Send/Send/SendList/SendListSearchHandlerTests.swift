import XCTest

@testable import BitwardenShared

final class SendListSearchHandlerTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SendListState, SendListAction, SendListEffect>!
    var subject: SendListSearchHandler!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SendListState())
        subject = SendListSearchHandler(
            store: Store(processor: processor)
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    /// Test that the handler relays search events.
    ///
    @MainActor
    func test_updateSearchResults_active() {
        let searchController = UISearchController()
        searchController.searchBar.text = "The Answer"

        subject.updateSearchResults(for: searchController)
        XCTAssertTrue(
            processor.dispatchedActions.contains(
                .searchTextChanged("The Answer")
            )
        )
    }

    /// Test that the handler relays search events.
    ///
    @MainActor
    func test_updateSearchResults_emptyText() {
        let searchController = UISearchController()
        searchController.searchBar.text = ""

        subject.updateSearchResults(for: searchController)
        XCTAssertTrue(
            processor.dispatchedActions.contains(
                .searchTextChanged("")
            )
        )
    }

    /// Test that the handler relays search events.
    ///
    @MainActor
    func test_updateSearchResults_nilText() {
        let searchController = UISearchController()
        searchController.searchBar.text = nil

        subject.updateSearchResults(for: searchController)
        XCTAssertTrue(
            processor.dispatchedActions.contains(
                .searchTextChanged("")
            )
        )
    }
}
