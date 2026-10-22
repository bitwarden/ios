import BitwardenKit
import BitwardenResources

// MARK: - AgentAccessAuditLogProcessor

/// The processor used to manage state and handle actions for the `AgentAccessAuditLogView`.
///
final class AgentAccessAuditLogProcessor: StateProcessor<
    AgentAccessAuditLogState,
    AgentAccessAuditLogAction,
    AgentAccessAuditLogEffect,
> {
    // MARK: Types

    typealias Services = HasAgentAccessRepository
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<AgentAccessRoute, Void>

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes an `AgentAccessAuditLogProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AgentAccessRoute, Void>,
        services: Services,
        state: AgentAccessAuditLogState,
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AgentAccessAuditLogEffect) async {
        switch effect {
        case .appeared:
            await loadEntries()
        }
    }

    override func receive(_ action: AgentAccessAuditLogAction) {
        switch action {
        case .clearPressed:
            coordinator.showAlert(.confirmationDestructive(
                title: Localizations.agentAccessAuditClear,
                message: Localizations.agentAccessAuditClearConfirm,
                destructiveTitle: Localizations.agentAccessAuditClear,
            ) { [weak self] in
                await self?.clear()
            })
        }
    }

    // MARK: Private Methods

    /// Clears the activity.
    ///
    private func clear() async {
        do {
            try await services.agentAccessRepository.clearAuditLog()
            state.entries = []
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }

    /// Loads the activity.
    ///
    private func loadEntries() async {
        defer { state.isLoading = false }
        do {
            state.entries = try await services.agentAccessRepository.auditLog()
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
