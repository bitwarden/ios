// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
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
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }
}
