import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import Combine
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SearchProcessorMediatorTests

class SearchProcessorMediatorTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var vaultRepository: MockVaultRepository!
    var subject: DefaultSearchProcessorMediator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = DefaultSearchProcessorMediator(
            errorReporter: errorReporter,
            vaultRepository: vaultRepository,
        )
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        vaultRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `startSearching(mode:onNewSearchResults:)` subscribes to the vault search list publisher
    /// and calls the closure with new results.
    @MainActor
    func test_startSearching() async throws {
        let cipherView = CipherListView.fixture(id: "cipher-id-123")
        try vaultRepository.vaultSearchListSubject.send(
            VaultListData(
                sections: [
                    VaultListSection(
                        id: "SearchResults",
                        items: [
                            XCTUnwrap(VaultListItem(cipherListView: cipherView)),
                        ],
                        name: "Search Results",
                    ),
                ],
            ),
        )

        var receivedData: VaultListData?
        subject.startSearching(mode: nil) { data in
            receivedData = data
        }
        subject.updateFilter(VaultListFilter(searchText: "test"))

        try await waitForAsync {
            receivedData?.sections.count == 1
        }

        XCTAssertEqual(
            receivedData?.sections.first?.items.first?.id,
            "cipher-id-123",
        )
    }

    /// `startSearching(mode:onNewSearchResults:)` cancels previous search when called multiple times.
    @MainActor
    func test_startSearching_cancelsPrevious() async throws {
        vaultRepository.vaultSearchListSubject.send(VaultListData())

        var callsCount = 0
        subject.startSearching(mode: nil) { _ in
            callsCount += 1
        }
        subject.startSearching(mode: nil) { _ in
            callsCount += 1
        }

        subject.updateFilter(VaultListFilter(searchText: "test"))

        try await waitForAsync {
            callsCount > 0
        }

        // Should only have one subscription active (second startSearching cancelled the first)
        XCTAssertEqual(callsCount, 1)
    }

    /// `stopSearching()` cancels the search subscription.
    @MainActor
    func test_stopSearching() async throws {
        vaultRepository.vaultSearchListSubject.send(VaultListData())

        var callsCount = 0
        subject.startSearching(mode: nil) { _ in
            callsCount += 1
        }
        subject.updateFilter(VaultListFilter(searchText: "first"))

        try await waitForAsync {
            callsCount == 1
        }

        subject.stopSearching()
        subject.updateFilter(VaultListFilter(searchText: "second"))

        try await Task.sleep(forSeconds: 1)

        // No new search results should be received after stopping
        XCTAssertEqual(callsCount, 1)
    }

    /// `updateFilter(_:)` sends the filter through the filter publisher.
    func test_updateFilter() async throws {
        let expectation = XCTestExpectation(description: "Filter received")
        let filter = VaultListFilter(searchText: "test")

        var receivedFilter: VaultListFilter?
        let cancellable = subject.vaultListFilterPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { value in
                    receivedFilter = value
                    expectation.fulfill()
                },
            )

        subject.updateFilter(filter)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedFilter?.searchText, "test")

        cancellable.cancel()
    }

    /// `updateFilter(_:)` removes duplicate filter emissions.
    func test_updateFilter_removeDuplicates() async throws {
        let expectation = XCTestExpectation(description: "Filter received once")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        let filter = VaultListFilter(searchText: "test")

        let cancellable = subject.vaultListFilterPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    expectation.fulfill()
                },
            )

        subject.updateFilter(filter)
        subject.updateFilter(filter)

        await fulfillment(of: [expectation], timeout: 1.0)

        cancellable.cancel()
    }
}

// MARK: - SearchProcessorMediatorFactoryTests

class SearchProcessorMediatorFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var vaultRepository: MockVaultRepository!
    var subject: DefaultSearchProcessorMediatorFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = DefaultSearchProcessorMediatorFactory(
            errorReporter: errorReporter,
            vaultRepository: vaultRepository,
        )
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        vaultRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `make()` creates a `DefaultSearchProcessorMediator` with the correct dependencies.
    func test_make() {
        let result = subject.make()

        XCTAssertTrue(result is DefaultSearchProcessorMediator)
    }
}
