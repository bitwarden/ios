// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessApprovalViewTests

class AgentAccessApprovalViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentAccessApprovalState, AgentAccessApprovalAction, AgentAccessApprovalEffect>!
    var subject: AgentAccessApprovalView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessApprovalState(
            requestId: "request-1",
            candidates: [
                AgentAccessUIFixtures.candidate(id: "cipher-1", name: "Example"),
                AgentAccessUIFixtures.candidate(id: "cipher-2", name: "Example work", username: "work@example.com"),
            ],
            connectionFingerprint: AgentAccessUIFixtures.fingerprint,
            connectionName: "Codex",
            query: .domain("example.com"),
            secondsRemaining: 90,
            selectedCipherId: "cipher-1",
            status: .pending,
        ))
        subject = AgentAccessApprovalView(store: Store(processor: processor))
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
        let button = try subject.inspect().find(asyncButton: Localizations.agentAccessApprove)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .approve)
    }

    /// The approve button is disabled until a login is selected.
    @MainActor
    func test_approveButton_disabledWithoutSelection() throws {
        processor.state.selectedCipherId = nil
        let button = try subject.inspect().find(asyncButton: Localizations.agentAccessApprove)
        XCTAssertTrue(button.isDisabled())
    }

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the deny button performs the `.deny` effect.
    @MainActor
    func test_denyButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.agentAccessDeny)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .deny)
    }

    /// Tapping a login dispatches the `.itemSelected` action.
    @MainActor
    func test_candidateRow_tap() throws {
        let button = try subject.inspect().find(button: "Example work")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .itemSelected("cipher-2"))
    }

    /// The description says who is asking for what, with the countdown and the agent's fingerprint.
    @MainActor
    func test_description() throws {
        XCTAssertNoThrow(try subject.inspect().find(
            text: Localizations.agentAccessApproveDescription("Codex", "example.com"),
        ))
        XCTAssertNoThrow(try subject.inspect().find(text: "abababab"))
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessSecondsLeft(90)))
    }

    /// Turning on the remember toggle dispatches the `.autoApproveToggled` action.
    @MainActor
    func test_autoApproveToggle_tap() throws {
        let toggle = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.agentAccessAutoApproveFor)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .autoApproveToggled(true))
    }

    /// The duration menu is only shown while the remember toggle is on.
    @MainActor
    func test_autoApproveDuration_visibleWhenOn() throws {
        XCTAssertThrowsError(try subject.inspect().find(
            viewWithAccessibilityIdentifier: "AgentAccessAutoApproveDurationChooser",
        ))

        processor.state.isAutoApproveOn = true
        XCTAssertNoThrow(try subject.inspect().find(
            viewWithAccessibilityIdentifier: "AgentAccessAutoApproveDurationChooser",
        ))
    }

    /// A message is shown instead of the list when no logins match, and only deny is offered.
    @MainActor
    func test_noMatchingItems() throws {
        processor.state.candidates = []
        processor.state.selectedCipherId = nil

        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessNoMatchingItems))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.agentAccessApprove))
        XCTAssertNoThrow(try subject.inspect().find(asyncButton: Localizations.agentAccessDeny))
        XCTAssertThrowsError(try subject.inspect().find(
            toggleWithAccessibilityLabel: Localizations.agentAccessAutoApproveFor,
        ))
    }

    /// The expired state offers no approval.
    @MainActor
    func test_status_expired() throws {
        processor.state.status = .expired
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessExpired))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.agentAccessApprove))
    }

    /// The failed state shows an error and offers no approval.
    @MainActor
    func test_status_failed() throws {
        processor.state.status = .failed
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.genericErrorMessage))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.agentAccessApprove))
    }

    /// A progress indicator is shown while the request loads.
    @MainActor
    func test_status_loading() throws {
        processor.state.status = .loading
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "AgentAccessApprovalLoading"))
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.agentAccessApprove))
    }
}
