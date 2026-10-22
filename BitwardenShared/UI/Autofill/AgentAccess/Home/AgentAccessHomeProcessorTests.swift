import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import Combine
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AgentAccessHomeProcessorTests

@MainActor
struct AgentAccessHomeProcessorTests {
    // MARK: Properties

    let agentAccessRepository: MockAgentAccessRepository
    let coordinator: MockCoordinator<AgentAccessRoute, Void>
    let errorReporter: MockErrorReporter
    let subject: AgentAccessHomeProcessor

    // MARK: Initialization

    init() {
        agentAccessRepository = MockAgentAccessRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        subject = AgentAccessHomeProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                agentAccessRepository: agentAccessRepository,
                errorReporter: errorReporter,
            ),
            state: AgentAccessHomeState(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` loads the saved values.
    @Test
    func perform_appeared() async {
        agentAccessRepository.isListeningEnabledReturnValue = true
        agentAccessRepository.relayURLReturnValue = "wss://relay.example.com"
        agentAccessRepository.autoApproveRulesReturnValue = [AgentAccessUIFixtures.autoApproveRule()]
        agentAccessRepository.connectionsReturnValue = [
            AgentAccessUIFixtures.connection(),
            AgentAccessUIFixtures.connection(fingerprint: String(repeating: "cd", count: 32)),
        ]

        await subject.perform(.appeared)

        #expect(subject.state.isListeningEnabled)
        #expect(subject.state.relayURL == "wss://relay.example.com")
        #expect(subject.state.relayURLInput == "wss://relay.example.com")
        #expect(subject.state.autoApproveRules == [AgentAccessUIFixtures.autoApproveRule()])
        #expect(subject.state.connectionsCount == 2)
    }

    /// `perform(_:)` with `.appeared` logs an error if the connections can't be loaded.
    @Test
    func perform_appeared_connectionsError() async {
        agentAccessRepository.isListeningEnabledReturnValue = false
        agentAccessRepository.relayURLReturnValue = AgentAccessConstants.defaultRelayURL
        agentAccessRepository.autoApproveRulesReturnValue = []
        agentAccessRepository.connectionsThrowableError = BitwardenTestError.example

        await subject.perform(.appeared)

        #expect(subject.state.connectionsCount == 0)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.removeRule` removes the rule and reloads the rules.
    @Test
    func perform_removeRule() async {
        subject.state.autoApproveRules = [AgentAccessUIFixtures.autoApproveRule()]
        agentAccessRepository.autoApproveRulesReturnValue = []

        await subject.perform(.removeRule(id: "rule-1"))

        #expect(agentAccessRepository.removeAutoApproveRuleReceivedId == "rule-1")
        #expect(subject.state.autoApproveRules.isEmpty)
    }

    /// `perform(_:)` with `.saveRelayURL` saves the trimmed address.
    @Test
    func perform_saveRelayURL() async {
        subject.state.relayURL = AgentAccessConstants.defaultRelayURL
        subject.state.relayURLInput = "  ws://localhost:8080  "

        await subject.perform(.saveRelayURL)

        #expect(agentAccessRepository.setRelayURLReceivedUrl == "ws://localhost:8080")
        #expect(subject.state.relayURL == "ws://localhost:8080")
        #expect(subject.state.relayURLInput == "ws://localhost:8080")
        #expect(subject.state.relayURLErrorMessage == nil)
        #expect(!subject.state.isRelayURLChanged)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// `perform(_:)` with `.saveRelayURL` shows a message under the field for an invalid address.
    @Test
    func perform_saveRelayURL_invalid() async {
        subject.state.relayURL = AgentAccessConstants.defaultRelayURL
        subject.state.relayURLInput = "http://example.com"
        agentAccessRepository.setRelayURLThrowableError = AgentAccessError.invalidRelayURL

        await subject.perform(.saveRelayURL)

        #expect(subject.state.relayURLErrorMessage == Localizations.agentAccessInvalidRelayURL)
        #expect(subject.state.relayURL == AgentAccessConstants.defaultRelayURL)
        #expect(coordinator.errorAlertsShown.isEmpty)
    }

    /// `perform(_:)` with `.saveRelayURL` shows an error alert for any other error.
    @Test
    func perform_saveRelayURL_error() async {
        subject.state.relayURLInput = "ws://localhost:8080"
        agentAccessRepository.setRelayURLThrowableError = BitwardenTestError.example

        await subject.perform(.saveRelayURL)

        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
        #expect(subject.state.relayURLErrorMessage == nil)
    }

    /// `perform(_:)` with `.setListening` turns listening on.
    @Test
    func perform_setListening_on() async {
        await subject.perform(.setListening(true))

        #expect(agentAccessRepository.setListeningEnabledReceivedEnabled == true)
        #expect(subject.state.isListeningEnabled)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// `perform(_:)` with `.setListening` turns listening off.
    @Test
    func perform_setListening_off() async {
        subject.state.isListeningEnabled = true

        await subject.perform(.setListening(false))

        #expect(agentAccessRepository.setListeningEnabledReceivedEnabled == false)
        #expect(!subject.state.isListeningEnabled)
    }

    /// `perform(_:)` with `.setListening` restores the saved value and shows an alert if it fails.
    @Test
    func perform_setListening_error() async {
        agentAccessRepository.setListeningEnabledThrowableError = BitwardenTestError.example
        agentAccessRepository.isListeningEnabledReturnValue = false

        await subject.perform(.setListening(true))

        #expect(!subject.state.isListeningEnabled)
        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(_:)` with `.streamStatus` updates the status as it changes.
    @Test
    func perform_streamStatus() async {
        agentAccessRepository.statusPublisherReturnValue = [
            AgentAccessConnectionStatus.connecting,
            .listening,
        ].publisher.eraseToAnyPublisher()

        await subject.perform(.streamStatus)

        #expect(subject.state.status == .listening)
        #expect(subject.state.statusText == Localizations.agentAccessStatusListening)
    }

    /// `receive(_:)` with `.auditLogPressed` navigates to the activity log.
    @Test
    func receive_auditLogPressed() {
        subject.receive(.auditLogPressed)

        #expect(coordinator.routes.last == .auditLog)
    }

    /// `receive(_:)` with `.connectionsPressed` navigates to the connections.
    @Test
    func receive_connectionsPressed() {
        subject.receive(.connectionsPressed)

        #expect(coordinator.routes.last == .connections)
    }

    /// `receive(_:)` with `.pairPressed` navigates to the pairing screen.
    @Test
    func receive_pairPressed() {
        subject.receive(.pairPressed)

        #expect(coordinator.routes.last == .pairing)
    }

    /// `receive(_:)` with `.relayURLChanged` updates the input and clears the error.
    @Test
    func receive_relayURLChanged() {
        subject.state.relayURL = "wss://relay.example.com"
        subject.state.relayURLErrorMessage = "Error"

        subject.receive(.relayURLChanged("ws://localhost:8080"))

        #expect(subject.state.relayURLInput == "ws://localhost:8080")
        #expect(subject.state.relayURLErrorMessage == nil)
        #expect(subject.state.isRelayURLChanged)
    }
}
