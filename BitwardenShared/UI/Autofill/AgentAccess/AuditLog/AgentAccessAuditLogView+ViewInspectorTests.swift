// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessAuditLogViewTests

class AgentAccessAuditLogViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentAccessAuditLogState, AgentAccessAuditLogAction, AgentAccessAuditLogEffect>!
    var subject: AgentAccessAuditLogView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessAuditLogState(
            entries: [
                AgentAccessUIFixtures.auditEntry(kind: .credentialApproved),
                AgentAccessUIFixtures.auditEntry(kind: .connectionEstablished, query: nil),
            ],
            isLoading: false,
        ))
        subject = AgentAccessAuditLogView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The entries show what happened and what was requested.
    @MainActor
    func test_entries() throws {
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessAuditCredentialApproved))
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessAuditConnectionEstablished))
        XCTAssertNoThrow(try subject.inspect().find(text: "example.com"))
    }

    /// Tapping the clear button dispatches the `.clearPressed` action.
    @MainActor
    func test_clearButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.agentAccessAuditClear)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .clearPressed)
    }

    /// The empty message is shown when there is no activity.
    @MainActor
    func test_empty() throws {
        processor.state.entries = []
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessAuditEmpty))
        XCTAssertThrowsError(try subject.inspect().find(button: Localizations.agentAccessAuditClear))
    }
}
