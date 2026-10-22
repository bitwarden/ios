import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - AgentAccessApprovalDelegate

/// An object that is notified when specific circumstances in the agent request screen have occurred.
///
@MainActor
protocol AgentAccessApprovalDelegate: AnyObject {
    /// The agent request has been answered.
    ///
    /// - Parameter approved: Whether the request was approved or denied.
    ///
    func agentAccessApprovalAnswered(approved: Bool)

    /// The agent request screen was closed.
    func agentAccessApprovalDismissed()
}

// MARK: - AgentAccessApprovalProcessor

/// The processor used to manage state and handle actions for the `AgentAccessApprovalView`.
///
final class AgentAccessApprovalProcessor: StateProcessor<
    AgentAccessApprovalState,
    AgentAccessApprovalAction,
    AgentAccessApprovalEffect,
> {
    // MARK: Types

    typealias Services = HasAgentAccessRepository
        & HasAuthRepository
        & HasBiometricsService
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<AgentAccessRoute, Void>

    /// The delegate that is notified when the request has been answered.
    private weak var delegate: AgentAccessApprovalDelegate?

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes an `AgentAccessApprovalProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - delegate: The object that is notified when the request has been answered.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AgentAccessRoute, Void>,
        delegate: AgentAccessApprovalDelegate?,
        services: Services,
        state: AgentAccessApprovalState,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AgentAccessApprovalEffect) async {
        switch effect {
        case .approve:
            await approve()
        case .deny:
            await submit(.deny)
        case .loadData:
            await loadData()
        case .streamCountdown:
            await streamCountdown()
        }
    }

    override func receive(_ action: AgentAccessApprovalAction) {
        switch action {
        case let .autoApproveMinutesChanged(minutes):
            state.autoApproveMinutes = minutes
        case let .autoApproveToggled(isOn):
            state.isAutoApproveOn = isOn
        case .dismiss:
            guard state.status == .pending else {
                let delegate = delegate
                coordinator.navigate(to: .dismiss(DismissAction {
                    delegate?.agentAccessApprovalDismissed()
                }))
                return
            }
            Task { await submit(.deny) }
        case let .itemSelected(id):
            state.selectedCipherId = id
        }
    }

    // MARK: Private Methods

    /// Verifies the user and approves the request with the selected login.
    ///
    private func approve() async {
        guard state.canApprove, let cipherId = state.selectedCipherId else { return }
        let decision = AgentAccessDecision.approve(
            cipherId: cipherId,
            autoApproveMinutes: state.isAutoApproveOn ? state.autoApproveMinutes : nil,
        )

        // Biometrics alone are enough to prove the user is present. They are skipped if the device
        // has none enrolled, and the user falls back to their master password if they cancel.
        if case .authorized = services.biometricsService.getBiometricAuthStatus() {
            do {
                if try await services.biometricsService.evaluateBiometricPolicy() {
                    await submit(decision)
                    return
                }
            } catch {
                // The prompt failed, so offer the master password.
            }
        }

        coordinator.showAlert(.masterPasswordPrompt { [weak self] password in
            await self?.verifyMasterPassword(password, thenSubmit: decision)
        })
    }

    /// Loads the request and finds the logins the user can choose from.
    ///
    private func loadData() async {
        guard let request = await services.agentAccessRepository.pendingRequest(id: state.requestId) else {
            state.status = .expired
            return
        }
        state.connectionFingerprint = request.connectionFingerprint
        state.connectionName = request.connectionName
        state.expiresAt = request.expiresAt
        state.query = request.query

        guard request.expiresAt > Date.now else {
            state.status = .expired
            return
        }

        do {
            let candidates = try await services.agentAccessRepository.candidates(for: state.requestId)
            state.candidates = candidates
            state.selectedCipherId = candidates.count == 1 ? candidates.first?.id : nil
            state.status = .pending
        } catch {
            state.status = .failed
            services.errorReporter.log(error: error)
        }
    }

    /// Counts down the time left to answer and shows the expired state when it runs out.
    ///
    private func streamCountdown() async {
        while !Task.isCancelled, state.status == .pending, let expiresAt = state.expiresAt {
            let remaining = Int(expiresAt.timeIntervalSinceNow.rounded(.up))
            guard remaining > 0 else {
                state.secondsRemaining = 0
                state.status = .expired
                return
            }
            state.secondsRemaining = remaining
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    /// Sends the user's decision.
    ///
    /// - Parameter decision: The decision to send.
    ///
    private func submit(_ decision: AgentAccessDecision) async {
        coordinator.showLoadingOverlay(title: Localizations.loading)
        do {
            try await services.agentAccessRepository.answer(requestId: state.requestId, decision: decision)
            coordinator.hideLoadingOverlay()

            let approved = if case .approve = decision { true } else { false }
            let delegate = delegate
            coordinator.navigate(to: .dismiss(DismissAction {
                delegate?.agentAccessApprovalAnswered(approved: approved)
                delegate?.agentAccessApprovalDismissed()
            }))
        } catch AgentAccessError.requestExpired, AgentAccessError.requestNotFound {
            coordinator.hideLoadingOverlay()
            state.status = .expired
        } catch {
            coordinator.hideLoadingOverlay()
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }

    /// Checks the master password the user entered and, if it's correct, sends the decision.
    ///
    /// - Parameters:
    ///   - password: The master password the user entered.
    ///   - decision: The decision to send once the password is verified.
    ///
    private func verifyMasterPassword(_ password: String, thenSubmit decision: AgentAccessDecision) async {
        do {
            guard try await services.authRepository.validatePassword(password) else {
                coordinator.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword))
                return
            }
            await submit(decision)
        } catch {
            await coordinator.showErrorAlert(error: error)
            services.errorReporter.log(error: error)
        }
    }
}
