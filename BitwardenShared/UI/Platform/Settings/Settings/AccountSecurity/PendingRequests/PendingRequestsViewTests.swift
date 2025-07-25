import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class PendingRequestsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PendingRequestsState, PendingRequestsAction, PendingRequestsEffect>!
    var subject: PendingRequestsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: PendingRequestsState())
        let store = Store(processor: processor)

        subject = PendingRequestsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the decline all requests button dispatches the `.declineAllRequests` action.
    @MainActor
    func test_declineAllRequestsButton_tap() throws {
        processor.state.loadingState = .data([.fixture()])
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.declineAllRequests)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .declineAllRequestsTapped)
    }

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    @MainActor
    func test_snapshot_empty() {
        processor.state.loadingState = .data([])
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The view with requests renders correctly.
    @MainActor
    func test_snapshot_requests() {
        processor.state.loadingState = .data([
            .fixture(fingerprintPhrase: "pineapple-on-pizza-is-the-best", id: "1"),
            .fixture(fingerprintPhrase: "coconuts-are-underrated", id: "2"),
        ])
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
