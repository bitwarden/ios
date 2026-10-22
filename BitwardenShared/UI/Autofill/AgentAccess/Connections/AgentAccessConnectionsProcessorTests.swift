import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AgentAccessConnectionsProcessorTests

@MainActor
struct AgentAccessConnectionsProcessorTests {
    // MARK: Properties

    let agentAccessRepository: MockAgentAccessRepository
    let coordinator: MockCoordinator<AgentAccessRoute, Void>
    let errorReporter: MockErrorReporter
    let subject: AgentAccessConnectionsProcessor

    // MARK: Initialization

    init() {
        agentAccessRepository = MockAgentAccessRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        subject = AgentAccessConnectionsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                agentAccessRepository: agentAccessRepository,
                errorReporter: errorReporter,
            ),
            state: AgentAccessConnectionsState(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` loads the connections, newest pairing first.
    @Test
    func perform_appeared() async {
        let older = AgentAccessConnection(
            fingerprint: String(repeating: "cd", count: 32),
            name: "Older",
            pairedAt: AgentAccessUIFixtures.referenceDate.addingTimeInterval(-3600),
            lastConnectedAt: AgentAccessUIFixtures.referenceDate,
        )
        let newer = AgentAccessUIFixtures.connection()
        agentAccessRepository.connectionsReturnValue = [older, newer]

        await subject.perform(.appeared)

        #expect(subject.state.connections == [newer, older])
        #expect(!subject.state.isLoading)
    }

    /// `perform(_:)` with `.appeared` shows an error alert if the connections can't be loaded.
    @Test
    func perform_appeared_error() async {
        agentAccessRepository.connectionsThrowableError = BitwardenTestError.example

        await subject.perform(.appeared)

        #expect(subject.state.connections.isEmpty)
        #expect(!subject.state.isLoading)
        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `receive(_:)` with `.revokePressed` asks for confirmation and revokes the connection once confirmed.
    @Test
    func receive_revokePressed() async throws {
        let connection = AgentAccessUIFixtures.connection()
        subject.state.connections = [connection]

        subject.receive(.revokePressed(connection))

        let alert = try #require(coordinator.alertShown.last)
        #expect(alert.title == Localizations.agentAccessRevoke)
        #expect(alert.message == Localizations.agentAccessRevokeConfirm("Codex"))
        #expect(!agentAccessRepository.revokeConnectionCalled)

        let revokeAction = try #require(alert.alertActions.first { $0.title == Localizations.agentAccessRevoke })
        await revokeAction.handler?(revokeAction, [])

        #expect(agentAccessRepository.revokeConnectionReceivedFingerprint == connection.fingerprint)
        #expect(subject.state.connections.isEmpty)
        #expect(!coordinator.isLoadingOverlayShowing)
    }

    /// `receive(_:)` with `.revokePressed` shows an error alert if revoking fails.
    @Test
    func receive_revokePressed_error() async throws {
        let connection = AgentAccessUIFixtures.connection()
        subject.state.connections = [connection]
        agentAccessRepository.revokeConnectionThrowableError = BitwardenTestError.example

        subject.receive(.revokePressed(connection))
        let alert = try #require(coordinator.alertShown.last)
        let revokeAction = try #require(alert.alertActions.first { $0.title == Localizations.agentAccessRevoke })
        await revokeAction.handler?(revokeAction, [])

        #expect(subject.state.connections == [connection])
        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `receive(_:)` with `.revokePressed` doesn't revoke when the user cancels.
    @Test
    func receive_revokePressed_cancel() throws {
        let connection = AgentAccessUIFixtures.connection()

        subject.receive(.revokePressed(connection))

        let alert = try #require(coordinator.alertShown.last)
        #expect(alert.alertActions.contains { $0.style == .cancel })
        #expect(!agentAccessRepository.revokeConnectionCalled)
    }
}
