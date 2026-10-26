import BitwardenKit
import BitwardenResources

// MARK: - AgentAccessConnectionsProcessor

/// The processor used to manage state and handle actions for the `AgentAccessConnectionsView`.
///
final class AgentAccessConnectionsProcessor: StateProcessor<
    AgentAccessConnectionsState,
    AgentAccessConnectionsAction,
    AgentAccessConnectionsEffect,
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

    /// Initializes an `AgentAccessConnectionsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AgentAccessRoute, Void>,
        services: Services,
        state: AgentAccessConnectionsState,
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AgentAccessConnectionsEffect) async {
        switch effect {
        case .appeared:
            await loadConnections()
        }
    }

    override func receive(_ action: AgentAccessConnectionsAction) {
        switch action {
        case let .revokePressed(connection):
            coordinator.showAlert(.confirmationDestructive(
                title: Localizations.agentAccessRevoke,
                message: Localizations.agentAccessRevokeConfirm(connection.displayName),
                destructiveTitle: Localizations.agentAccessRevoke,
            ) { [weak self] in
                await self?.revoke(connection)
            })
        }
    }

    // MARK: Private Methods

    /// Loads the paired agents, newest first.
    ///
    private func loadConnections() async {
        defer { state.isLoading = false }
        do {
            state.connections = try await services.agentAccessRepository.connections()
                .sorted { $0.pairedAt > $1.pairedAt }
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }

    /// Revokes access for a connection.
    ///
    /// - Parameter connection: The connection to revoke.
    ///
    private func revoke(_ connection: AgentAccessConnection) async {
        coordinator.showLoadingOverlay(title: Localizations.loading)
        defer { coordinator.hideLoadingOverlay() }

        do {
            try await services.agentAccessRepository.revokeConnection(fingerprint: connection.fingerprint)
            state.connections.removeAll { $0.fingerprint == connection.fingerprint }
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
