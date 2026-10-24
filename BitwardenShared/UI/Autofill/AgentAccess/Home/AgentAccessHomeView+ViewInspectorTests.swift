// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import UserNotifications
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

    /// The relay server field is hidden until the advanced section is expanded.
    @MainActor
    func test_relayURLField_collapsedByDefault() throws {
        XCTAssertThrowsError(try subject.inspect().find(bitwardenTextField: Localizations.agentAccessRelayServer))
        XCTAssertNoThrow(try subject.inspect().find(button: Localizations.advanced))

        processor.state.isAdvancedExpanded = true
        XCTAssertNoThrow(try subject.inspect().find(bitwardenTextField: Localizations.agentAccessRelayServer))
    }

    /// Tapping the advanced button dispatches the `.advancedPressed` action.
    @MainActor
    func test_advancedButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.advanced)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .advancedPressed)
    }

    /// The reset button is only shown for a custom relay server.
    @MainActor
    func test_resetButton_hiddenForDefault() throws {
        processor.state.isAdvancedExpanded = true
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.agentAccessResetRelay))

        processor.state.relayURL = "wss://custom.example.com"
        XCTAssertNoThrow(try subject.inspect().find(asyncButton: Localizations.agentAccessResetRelay))
    }

    /// Tapping the reset button performs the `.resetRelayURL` effect.
    @MainActor
    func test_resetButton_tap() async throws {
        processor.state.isAdvancedExpanded = true
        processor.state.relayURL = "wss://custom.example.com"
        let button = try subject.inspect().find(asyncButton: Localizations.agentAccessResetRelay)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .resetRelayURL)
    }

    /// Updating the relay server field dispatches the `.relayURLChanged` action.
    @MainActor
    func test_relayURLField_updated() throws {
        processor.state.isAdvancedExpanded = true
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.agentAccessRelayServer)
        try textField.inputBinding().wrappedValue = "wss://custom.example.com"
        XCTAssertEqual(processor.dispatchedActions.last, .relayURLChanged("wss://custom.example.com"))
    }

    /// The save button is hidden until the relay server address changes.
    @MainActor
    func test_saveButton_hiddenUntilChanged() throws {
        processor.state.isAdvancedExpanded = true
        XCTAssertThrowsError(try subject.inspect().find(asyncButton: Localizations.save))

        processor.state.relayURLInput = "wss://custom.example.com"
        XCTAssertNoThrow(try subject.inspect().find(asyncButton: Localizations.save))
    }

    /// Tapping the save button performs the `.saveRelayURL` effect.
    @MainActor
    func test_saveButton_tap() async throws {
        processor.state.isAdvancedExpanded = true
        processor.state.relayURLInput = "wss://custom.example.com"
        let button = try subject.inspect().find(asyncButton: Localizations.save)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .saveRelayURL)
    }

    /// The relay server error is shown under the field.
    @MainActor
    func test_relayURLError() throws {
        processor.state.isAdvancedExpanded = true
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

    /// The notifications warning is hidden when notifications are allowed.
    @MainActor
    func test_notificationsWarning_hiddenWhenAllowed() {
        processor.state.notificationAuthorization = .authorized
        XCTAssertThrowsError(try subject.inspect().find(text: Localizations.agentAccessNotificationsOffWarning))
    }

    /// The notifications warning is hidden when Agent Access is off.
    @MainActor
    func test_notificationsWarning_hiddenWhenListeningOff() {
        processor.state.isListeningEnabled = false
        processor.state.notificationAuthorization = .denied
        XCTAssertThrowsError(try subject.inspect().find(text: Localizations.agentAccessNotificationsOffWarning))
    }

    /// Tapping the open settings button in the warning performs the `.turnOnNotifications` effect.
    @MainActor
    func test_notificationsWarning_denied_tap() async throws {
        processor.state.notificationAuthorization = .denied
        XCTAssertNoThrow(try subject.inspect().find(text: Localizations.agentAccessNotificationsOffWarning))
        let button = try subject.inspect().find(asyncButton: Localizations.openSettings)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .turnOnNotifications)
    }

    /// Tapping the turn on button in the warning performs the `.turnOnNotifications` effect when
    /// permission hasn't been decided.
    @MainActor
    func test_notificationsWarning_notDetermined_tap() async throws {
        processor.state.notificationAuthorization = .notDetermined
        let button = try subject.inspect().find(asyncButton: Localizations.turnOnNow)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .turnOnNotifications)
    }
}
