import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AgentAccessAuditLogProcessorTests

@MainActor
struct AgentAccessAuditLogProcessorTests {
    // MARK: Properties

    let agentAccessRepository: MockAgentAccessRepository
    let coordinator: MockCoordinator<AgentAccessRoute, Void>
    let errorReporter: MockErrorReporter
    let subject: AgentAccessAuditLogProcessor

    // MARK: Initialization

    init() {
        agentAccessRepository = MockAgentAccessRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        subject = AgentAccessAuditLogProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                agentAccessRepository: agentAccessRepository,
                errorReporter: errorReporter,
            ),
            state: AgentAccessAuditLogState(),
        )
    }

    // MARK: Tests

    /// `perform(_:)` with `.appeared` loads the entries.
    @Test
    func perform_appeared() async {
        let entries = [
            AgentAccessUIFixtures.auditEntry(kind: .credentialApproved),
            AgentAccessUIFixtures.auditEntry(kind: .connectionEstablished, query: nil),
        ]
        agentAccessRepository.auditLogReturnValue = entries

        await subject.perform(.appeared)

        #expect(subject.state.entries == entries)
        #expect(!subject.state.isLoading)
    }

    /// `perform(_:)` with `.appeared` shows an error alert if the entries can't be loaded.
    @Test
    func perform_appeared_error() async {
        agentAccessRepository.auditLogThrowableError = BitwardenTestError.example

        await subject.perform(.appeared)

        #expect(subject.state.entries.isEmpty)
        #expect(!subject.state.isLoading)
        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `receive(_:)` with `.clearPressed` asks for confirmation and clears the entries once confirmed.
    @Test
    func receive_clearPressed() async throws {
        subject.state.entries = [AgentAccessUIFixtures.auditEntry()]

        subject.receive(.clearPressed)

        let alert = try #require(coordinator.alertShown.last)
        #expect(alert.title == Localizations.agentAccessAuditClear)
        #expect(alert.message == Localizations.agentAccessAuditClearConfirm)
        #expect(!agentAccessRepository.clearAuditLogCalled)

        let clearAction = try #require(alert.alertActions.first { $0.title == Localizations.agentAccessAuditClear })
        await clearAction.handler?(clearAction, [])

        #expect(agentAccessRepository.clearAuditLogCalled)
        #expect(subject.state.entries.isEmpty)
    }

    /// `receive(_:)` with `.clearPressed` keeps the entries and shows an error alert if clearing fails.
    @Test
    func receive_clearPressed_error() async throws {
        let entries = [AgentAccessUIFixtures.auditEntry()]
        subject.state.entries = entries
        agentAccessRepository.clearAuditLogThrowableError = BitwardenTestError.example

        subject.receive(.clearPressed)
        let alert = try #require(coordinator.alertShown.last)
        let clearAction = try #require(alert.alertActions.first { $0.title == Localizations.agentAccessAuditClear })
        await clearAction.handler?(clearAction, [])

        #expect(subject.state.entries == entries)
        #expect(coordinator.errorAlertsShown.last as? BitwardenTestError == .example)
    }

    /// Every audit kind has its own localized name.
    @Test
    func auditKind_localizedName() {
        let names = Set([
            AgentAccessAuditKind.connectionEstablished,
            .sessionRefreshed,
            .connectionRejected,
            .connectionRevoked,
            .credentialRequested,
            .credentialApproved,
            .credentialAutoApproved,
            .credentialDenied,
            .credentialExpired,
        ].map(\.localizedName))

        #expect(names.count == 9)
        #expect(
            AgentAccessAuditKind.credentialApproved.localizedName == Localizations.agentAccessAuditCredentialApproved,
        )
    }
}
