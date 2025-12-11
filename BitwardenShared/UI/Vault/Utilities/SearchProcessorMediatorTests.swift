import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import Combine
import TestHelpers
import XCTest

@testable import BitwardenShared

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

    /// `onFilterChanged(_:)` sends the filter through the filter publisher.
    func test_onFilterChanged() async throws {
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

        subject.onFilterChanged(filter)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedFilter?.searchText, "test")

        cancellable.cancel()
    }

    /// `onFilterChanged(_:)` removes duplicate filter emissions.
    func test_onFilterChanged_removeDuplicates() async throws {
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

        subject.onFilterChanged(filter)
        subject.onFilterChanged(filter)

        await fulfillment(of: [expectation], timeout: 1.0)

        cancellable.cancel()
    }

    /// `setAutofillListMode(_:)` sets the autofill list mode.
    func test_setAutofillListMode() {
        subject.setAutofillListMode(.passwords)

        vaultRepository.vaultSearchListSubject.send(
            VaultListData(),
        )

        subject.startSearching()

        XCTAssertEqual(vaultRepository.vaultSearchListPublisherMode, .passwords)
    }

    /// `setDelegate(_:)` sets the delegate.
    @MainActor
    func test_setDelegate() async throws {
        let delegate = MockSearchProcessorMediatorDelegate()
        subject.setDelegate(delegate)

        vaultRepository.vaultSearchListSubject.send(
            VaultListData(),
        )

        subject.startSearching()
        subject.onFilterChanged(VaultListFilter(searchText: "test"))

        try await waitForAsync {
            delegate.onNewSearchResultsCallsCount == 1
        }
    }

    /// `startSearching()` subscribes to the vault search list publisher and send the new results to the delegate.
    @MainActor
    func test_startSearching() async throws {
        let delegate = MockSearchProcessorMediatorDelegate()
        subject.setDelegate(delegate)

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

        subject.startSearching()
        subject.onFilterChanged(VaultListFilter(searchText: "test"))

        try await waitForAsync {
            delegate.onNewSearchResultsReceivedData?.sections.count == 1
        }

        XCTAssertEqual(
            delegate.onNewSearchResultsReceivedData?.sections.first?.items.first?.id,
            "cipher-id-123",
        )
    }

    /// `startSearching()` cancels previous search when called multiple times.
    @MainActor
    func test_startSearching_cancelsPrevious() async throws {
        let delegate = MockSearchProcessorMediatorDelegate()
        subject.setDelegate(delegate)

        vaultRepository.vaultSearchListSubject.send(VaultListData())

        subject.startSearching()
        subject.startSearching()

        subject.onFilterChanged(VaultListFilter(searchText: "test"))

        try await waitForAsync {
            delegate.onNewSearchResultsCallsCount > 0
        }

        // Should only have one subscription active (second startSearching cancelled the first)
        XCTAssertEqual(delegate.onNewSearchResultsCallsCount, 1)
    }

    /// `stopSearching()` cancels the search subscription.
    @MainActor
    func test_stopSearching() async throws {
        let delegate = MockSearchProcessorMediatorDelegate()
        subject.setDelegate(delegate)

        vaultRepository.vaultSearchListSubject.send(VaultListData())

        subject.startSearching()
        subject.onFilterChanged(VaultListFilter(searchText: "first"))

        try await waitForAsync {
            delegate.onNewSearchResultsCallsCount == 1
        }

        subject.stopSearching()
        subject.onFilterChanged(VaultListFilter(searchText: "second"))

        try await Task.sleep(forSeconds: 1)

        // No new search results should be received after stopping
        XCTAssertEqual(delegate.onNewSearchResultsCallsCount, 1)
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
