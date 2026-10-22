import BitwardenKit
import BitwardenResources
import Combine

// MARK: - AgentAccessHomeProcessor

/// The processor used to manage state and handle actions for the `AgentAccessHomeView`.
///
final class AgentAccessHomeProcessor: StateProcessor<
    AgentAccessHomeState,
    AgentAccessHomeAction,
    AgentAccessHomeEffect,
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

    /// Initializes an `AgentAccessHomeProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AgentAccessRoute, Void>,
        services: Services,
        state: AgentAccessHomeState,
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AgentAccessHomeEffect) async {
        switch effect {
        case .appeared:
            await loadData()
        case let .removeRule(id):
            await services.agentAccessRepository.removeAutoApproveRule(id: id)
            state.autoApproveRules = await services.agentAccessRepository.autoApproveRules()
        case .saveRelayURL:
            await saveRelayURL()
        case let .setListening(enabled):
            await setListening(enabled)
        case .streamStatus:
            for await status in services.agentAccessRepository.statusPublisher().values {
                state.status = status
            }
        }
    }

    override func receive(_ action: AgentAccessHomeAction) {
        switch action {
        case .auditLogPressed:
            coordinator.navigate(to: .auditLog)
        case .connectionsPressed:
            coordinator.navigate(to: .connections)
        case .pairPressed:
            coordinator.navigate(to: .pairing)
        case let .relayURLChanged(url):
            state.relayURLInput = url
            state.relayURLErrorMessage = nil
        }
    }

    // MARK: Private Methods

    /// Loads the saved values shown on the screen.
    ///
    private func loadData() async {
        let repository = services.agentAccessRepository
        state.isListeningEnabled = await repository.isListeningEnabled()
        let relayURL = await repository.relayURL()
        state.relayURL = relayURL
        state.relayURLInput = relayURL
        state.relayURLErrorMessage = nil
        state.autoApproveRules = await repository.autoApproveRules()
        do {
            state.connectionsCount = try await repository.connections().count
        } catch {
            state.connectionsCount = 0
            services.errorReporter.log(error: error)
        }
    }

    /// Saves the relay server address and reconnects.
    ///
    private func saveRelayURL() async {
        let url = state.relayURLInput.trimmingCharacters(in: .whitespacesAndNewlines)
        coordinator.showLoadingOverlay(title: Localizations.saving)
        defer { coordinator.hideLoadingOverlay() }

        do {
            try await services.agentAccessRepository.setRelayURL(url)
            state.relayURL = url
            state.relayURLInput = url
            state.relayURLErrorMessage = nil
        } catch AgentAccessError.invalidRelayURL {
            state.relayURLErrorMessage = Localizations.agentAccessInvalidRelayURL
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }

    /// Turns listening for agent requests on or off.
    ///
    /// - Parameter enabled: Whether listening should be on.
    ///
    private func setListening(_ enabled: Bool) async {
        coordinator.showLoadingOverlay(title: Localizations.loading)
        defer { coordinator.hideLoadingOverlay() }

        do {
            try await services.agentAccessRepository.setListeningEnabled(enabled)
            state.isListeningEnabled = enabled
        } catch {
            state.isListeningEnabled = await services.agentAccessRepository.isListeningEnabled()
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
