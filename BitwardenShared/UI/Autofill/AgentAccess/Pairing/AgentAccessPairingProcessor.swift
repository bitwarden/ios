import BitwardenKit
import BitwardenResources
import Combine
import Foundation

// MARK: - AgentAccessPairingProcessor

/// The processor used to manage state and handle actions for the `AgentAccessPairingView`.
///
final class AgentAccessPairingProcessor: StateProcessor<
    AgentAccessPairingState,
    AgentAccessPairingAction,
    AgentAccessPairingEffect,
> {
    // MARK: Types

    typealias Services = HasAgentAccessRepository
        & HasErrorReporter
        & HasPasteboardService

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<AgentAccessRoute, Void>

    /// How long the success message stays on screen before the screen closes.
    private let pairedDismissDelay: TimeInterval

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes an `AgentAccessPairingProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - pairedDismissDelay: How long the success message stays on screen before the screen closes.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AgentAccessRoute, Void>,
        pairedDismissDelay: TimeInterval = 1.5,
        services: Services,
        state: AgentAccessPairingState,
    ) {
        self.coordinator = coordinator
        self.pairedDismissDelay = pairedDismissDelay
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AgentAccessPairingEffect) async {
        switch effect {
        case .startPairing:
            await startPairing()
        case .streamEvents:
            await streamEvents()
        }
    }

    override func receive(_ action: AgentAccessPairingAction) {
        switch action {
        case .confirmFingerprint:
            answerFingerprint(approved: true)
        case let .connectionNameChanged(name):
            state.connectionName = name
        case .copyToken:
            guard let token = state.pairing?.token else { return }
            services.pasteboardService.copy(token)
            state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.agentAccessToken))
        case let .modeChanged(mode):
            state.mode = mode
        case .rejectFingerprint:
            answerFingerprint(approved: false)
        case .shareToken:
            guard let token = state.pairing?.token else { return }
            coordinator.navigate(to: .share(text: token))
        case let .toastShown(toast):
            state.toast = toast
        case .tryAgain:
            state.pairing = nil
            state.phase = .form
        }
    }

    // MARK: Private Methods

    /// Delivers the user's answer to the fingerprint comparison.
    ///
    /// - Parameter approved: Whether the codes match.
    ///
    private func answerFingerprint(approved: Bool) {
        guard case let .verifying(verification) = state.phase else { return }
        services.agentAccessRepository.answerFingerprintVerification(id: verification.id, approved: approved)
        state.phase = .waiting
    }

    /// Handles an event for the pairing in progress.
    ///
    /// - Parameter event: The event to handle.
    /// - Returns: Whether the pairing is finished and no more events are needed.
    ///
    private func handle(_ event: AgentAccessPairingEvent) async -> Bool {
        switch event {
        case .waitingForAgent:
            state.phase = .waiting
            return false
        case let .verifyFingerprint(verification):
            state.phase = .verifying(verification)
            return false
        case let .paired(connection):
            state.phase = .paired(connection)
            if pairedDismissDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(pairedDismissDelay * 1_000_000_000))
            }
            coordinator.navigate(to: .back)
            return true
        case .rejected:
            state.phase = .rejected
            return true
        case let .failed(message):
            state.phase = .failed(message: message)
            return true
        }
    }

    /// Creates the token or code and starts waiting for the agent.
    ///
    private func startPairing() async {
        guard state.canStartPairing else { return }
        let name = state.connectionName.trimmingCharacters(in: .whitespacesAndNewlines)

        coordinator.showLoadingOverlay(title: Localizations.loading)
        defer { coordinator.hideLoadingOverlay() }

        do {
            state.pairing = try await services.agentAccessRepository.createPairing(kind: state.mode.kind, name: name)
            state.phase = .waiting
        } catch {
            services.errorReporter.log(error: error)
            state.phase = .failed(message: "")
        }
    }

    /// Updates the screen as the pairing in progress reports events.
    ///
    private func streamEvents() async {
        guard state.pairing != nil else { return }
        for await event in services.agentAccessRepository.pairingEventsPublisher().values {
            let isFinished = await handle(event)
            if isFinished { return }
        }
    }
}
