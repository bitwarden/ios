// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessConnectionsViewTests

class AgentAccessConnectionsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        AgentAccessConnectionsState,
        AgentAccessConnectionsAction,
        AgentAccessConnectionsEffect,
    >!
    var subject: AgentAccessConnectionsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessConnectionsState(
            connections: [AgentAccessUIFixtures.connection()],
            isLoading: false,
        ))
        subject = AgentAccessConnectionsView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The connection's name and fingerprint prefix are shown.
    @MainActor
    func test_connection() throws {
        XCTAssertNoThrow(try subject.inspect().find(text: "Codex"))
        XCTAssertNoThrow(try subject.inspect().find(text: "abababab"))
    }

    /// A connection without a name shows its fingerprint prefix as the name.
    @MainActor
    func test_connection_noName() throws {
        processor.state.connections = [AgentAccessUIFixtures.connection(name: nil)]
        XCTAssertThrowsError(try subject.inspect().find(text: "Codex"))
        XCTAssertNoThrow(try subject.inspect().find(text: "abababab"))
    }

    /// Tapping the revoke button dispatches the `.revokePressed` action.
    @MainActor
    func test_revokeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.agentAccessRevoke)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .revokePressed(AgentAccessUIFixtures.connection()))
    }

    /// The empty message is shown when no agents are paired.
    @MainActor
    func test_empty() throws {
        processor.state.connections = []
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessConnectionsEmpty))
        XCTAssertThrowsError(try subject.inspect().find(button: Localizations.agentAccessRevoke))
    }

    /// A progress indicator is shown while loading.
    @MainActor
    func test_loading() throws {
        processor.state.isLoading = true
        XCTAssertThrowsError(try subject.inspect().find(text: Localizations.agentAccessConnectionsEmpty))
        XCTAssertNoThrow(try subject.inspect().find(viewWithAccessibilityIdentifier: "AgentAccessConnectionsLoading"))
    }
}
