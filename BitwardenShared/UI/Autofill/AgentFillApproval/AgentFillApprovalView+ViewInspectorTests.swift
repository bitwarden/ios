// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AgentFillApprovalViewTests

class AgentFillApprovalViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentFillApprovalState, AgentFillApprovalAction, AgentFillApprovalEffect>!
    var subject: AgentFillApprovalView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentFillApprovalState(
            approvalId: "approval-1",
            browserName: "Chrome",
            connectionName: "Claude Desktop",
            domain: "delta.com",
            items: [
                AgentFillApprovalItem(id: "cipher-1", name: "Delta", subtitle: "user@example.com"),
                AgentFillApprovalItem(id: "cipher-2", name: "Delta work", subtitle: "work@example.com"),
            ],
            selectedItemId: "cipher-1",
            status: .pending,
        ))
        subject = AgentFillApprovalView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the approve button performs the `.approve` effect.
    @MainActor
    func test_approveButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.aiAgentFillApprove)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .approve)
    }

    /// The approve button is disabled until an item is selected.
    @MainActor
    func test_approveButton_disabledWithoutSelection() throws {
        processor.state.selectedItemId = nil
        let button = try subject.inspect().find(asyncButton: Localizations.aiAgentFillApprove)
        XCTAssertTrue(button.isDisabled())
    }

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the deny options performs the `.deny(reason:)` effect with the matching reason.
    @MainActor
    func test_denyOptions_tap() async throws {
        var button = try subject.inspect().find(asyncButton: Localizations.aiAgentFillDenyNoReason)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .deny(reason: nil))

        button = try subject.inspect().find(asyncButton: Localizations.aiAgentFillDenyWrongAccount)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .deny(reason: .wrongAccount))

        button = try subject.inspect().find(asyncButton: Localizations.aiAgentFillDenyNotRequested)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .deny(reason: .notRequested))
    }

    /// Tapping an item dispatches the `.itemSelected` action.
    @MainActor
    func test_itemRow_tap() throws {
        let button = try subject.inspect().find(button: "Delta work")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemSelected("cipher-2"))
    }

    /// The request's connection, domain and browser are described for a login.
    @MainActor
    func test_description_login() throws {
        let text = try subject.inspect().find(
            text: Localizations.aiAgentFillLoginDescription("Claude Desktop", "delta.com", "Chrome"),
        )
        XCTAssertNotNil(text)
    }

    /// The request's connection, domain and browser are described for a card.
    @MainActor
    func test_description_card() throws {
        processor.state.cipherType = .card
        let text = try subject.inspect().find(
            text: Localizations.aiAgentFillCardDescription("Claude Desktop", "delta.com", "Chrome"),
        )
        XCTAssertNotNil(text)
    }

    /// A message is shown instead of the list when no items match.
    @MainActor
    func test_noMatchingItems() throws {
        processor.state.items = []
        processor.state.selectedItemId = nil
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.aiAgentFillNoMatchingItems))
    }

    /// The handled state offers no approval.
    @MainActor
    func test_status_handled() throws {
        processor.state.status = .handled
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.aiAgentFillHandled))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.aiAgentFillApprove))
    }

    /// The expired state offers no approval.
    @MainActor
    func test_status_expired() throws {
        processor.state.status = .expired
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.aiAgentFillExpired))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.aiAgentFillApprove))
    }

    /// The failed state shows an error and offers no approval.
    @MainActor
    func test_status_failed() throws {
        processor.state.status = .failed
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.aiAgentFillCouldNotOpen))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.aiAgentFillApprove))
    }
}
