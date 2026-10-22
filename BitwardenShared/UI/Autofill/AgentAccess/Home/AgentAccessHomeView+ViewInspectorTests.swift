// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AgentAccessHomeViewTests

class AgentAccessHomeViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AgentAccessHomeState, AgentAccessHomeAction, AgentAccessHomeEffect>!
    var subject: AgentAccessHomeView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AgentAccessHomeState(
            isListeningEnabled: true,
            relayURL: AgentAccessConstants.defaultRelayURL,
            relayURLInput: AgentAccessConstants.defaultRelayURL,
            status: .listening,
        ))
        subject = AgentAccessHomeView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the activity row dispatches the `.auditLogPressed` action.
    @MainActor
    func test_auditLogButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.agentAccessAuditLog)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .auditLogPressed)
    }

    /// Tapping the connections row dispatches the `.connectionsPressed` action.
    @MainActor
    func test_connectionsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.agentAccessConnections)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .connectionsPressed)
    }

    /// Tapping the pair an agent row dispatches the `.pairPressed` action.
    @MainActor
    func test_pairButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.agentAccessPairAgent)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .pairPressed)
    }

    /// Updating the relay server field dispatches the `.relayURLChanged` action.
    @MainActor
    func test_relayURLField_updated() throws {
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.agentAccessRelayServer)
        try textField.inputBinding().wrappedValue = "ws://localhost:8080"
        XCTAssertEqual(processor.dispatchedActions.last, .relayURLChanged("ws://localhost:8080"))
    }

    /// The save button is hidden until the relay server address changes.
    @MainActor
    func test_saveButton_hiddenUntilChanged() throws {
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.save))

        processor.state.relayURLInput = "ws://localhost:8080"
        XCTAssertNoThrow(try subject.inspect().find(asyncButton: Localizations.save))
    }

    /// Tapping the save button performs the `.saveRelayURL` effect.
    @MainActor
    func test_saveButton_tap() async throws {
        processor.state.relayURLInput = "ws://localhost:8080"
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .saveRelayURL)
    }

    /// The relay server error is shown under the field.
    @MainActor
    func test_relayURLError() throws {
        processor.state.relayURLErrorMessage = Localizations.agentAccessInvalidRelayURL
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessInvalidRelayURL))
    }

    /// Turning the toggle on performs the `.setListening` effect.
    @MainActor
    func test_allowRequestsToggle_tap() throws {
        processor.state.isListeningEnabled = false
        let toggle = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.agentAccessAllowRequests)
        XCTAssertFalse(try toggle.isOn())

        let task = Task {
            try toggle.tap()
        }
        defer { task.cancel() }
        waitFor(processor.effects.last == .setListening(true))
    }

    /// The status text describes the connection.
    @MainActor
    func test_status() throws {
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessStatusListening))

        processor.state.status = .reconnecting
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessStatusReconnecting))
    }

    /// The privacy note is shown.
    @MainActor
    func test_privacyFooter() throws {
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessPrivacyFooter))
    }

    /// The automatic approvals are listed and can be stopped.
    @MainActor
    func test_autoApproveRule_stop() async throws {
        processor.state.autoApproveRules = [AgentAccessUIFixtures.autoApproveRule()]
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessAutoApproveRules))

        let button = try subject.inspect().find(asyncButton: Localizations.agentAccessAutoApproveRemove)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .removeRule(id: "rule-1"))
    }

    /// The automatic approvals section is hidden when there are none.
    @MainActor
    func test_autoApproveRules_hidden() {
        XCTAssertThrowsError(try subject.inspect().find(text: Localizations.agentAccessAutoApproveRules))
    }
}
