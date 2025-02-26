import XCTest

@testable import BitwardenShared

final class VaultGroupSearchHandlerTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultGroupState, VaultGroupAction, VaultGroupEffect>!
    var subject: VaultGroupSearchHandler!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: VaultGroupState(
                searchVaultFilterType: .allVaults,
                vaultFilterType: .allVaults
            )
        )
        subject = VaultGroupSearchHandler(
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
