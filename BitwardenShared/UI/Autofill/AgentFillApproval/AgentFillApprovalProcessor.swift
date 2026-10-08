import BitwardenKit
import BitwardenResources
import BitwardenSdk

// MARK: - AgentFillApprovalDelegate

/// An object that is notified when specific circumstances in the agent fill approval screen have
/// occurred.
///
@MainActor
protocol AgentFillApprovalDelegate: AnyObject {
    /// The agent fill approval request has been answered.
    ///
    /// - Parameter approved: Whether the request was approved or denied.
    ///
    func agentFillApprovalAnswered(approved: Bool)
}

// MARK: - AgentFillApprovalProcessor

/// The processor used to manage state and handle actions for the `AgentFillApprovalView`.
///
final class AgentFillApprovalProcessor: StateProcessor<
    AgentFillApprovalState,
    AgentFillApprovalAction,
    AgentFillApprovalEffect,
> {
    // MARK: Types

    typealias Services = HasAgentFillApprovalRepository
        & HasAuthRepository
        & HasBiometricsService
        & HasErrorReporter

    // MARK: Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<AgentFillApprovalRoute, Void>

    /// The delegate that is notified when the approval request has been answered.
    private weak var delegate: AgentFillApprovalDelegate?

    /// The opened request, which carries the challenge that the answer has to echo.
    private var openedRequest: OpenedApprovalRequest?

    /// The services used by the processor.
    private let services: Services

    // MARK: Initialization

    /// Initializes an `AgentFillApprovalProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator used for navigation.
    ///   - delegate: The object that is notified when the request has been answered.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<AgentFillApprovalRoute, Void>,
        delegate: AgentFillApprovalDelegate?,
        services: Services,
        state: AgentFillApprovalState,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.services = services

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: AgentFillApprovalEffect) async {
        switch effect {
        case .approve:
            await approve()
        case let .deny(reason):
            await submit(.denied(reason: reason))
        case .loadData:
            await loadData()
        }
    }

    override func receive(_ action: AgentFillApprovalAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss())
        case let .itemSelected(id):
            state.selectedItemId = id
        }
    }

    // MARK: Private Methods

    /// Verifies the user and approves the request with the selected item.
    ///
    private func approve() async {
        guard state.canApprove, let cipherId = state.selectedItemId else { return }
        let decision = ApprovalDecision.approved(cipherId: cipherId)

        // Biometrics alone are enough to prove the user is present. They are skipped if the device
        // has none enrolled, and the user falls back to their master password if they cancel.
        if case .authorized = services.biometricsService.getBiometricAuthStatus() {
            do {
                if try await services.biometricsService.evaluateBiometricPolicy(
                    reason: Localizations.aiAgentFillBiometricPrompt,
                ) {
                    await submit(decision)
                    return
                }
            } catch {
                // The prompt was cancelled or failed, so offer the master password.
            }
        }

        coordinator.showAlert(.masterPasswordPrompt { [weak self] password in
            await self?.verifyMasterPassword(password, thenSubmit: decision)
        })
    }

    /// Fetches and opens the request, and finds the items the user can choose from.
    ///
    private func loadData() async {
        do {
            let (record, opened) = try await services.agentFillApprovalRepository.open(state.approvalId)
            openedRequest = opened
            state.browserName = opened.view.browserName
            state.cipherType = opened.view.cipherType
            state.connectionName = opened.view.connectionName
            state.domain = opened.view.domain

            guard !record.isAnswered else {
                state.status = .handled
                return
            }
            guard !record.isExpired else {
                state.status = .expired
                return
            }

            let ciphers = try await services.agentFillApprovalRepository.fetchApprovableCiphers(for: opened.view)
            state.items = ciphers.compactMap { cipher in
                guard let id = cipher.id else { return nil }
                return AgentFillApprovalItem(id: id, name: cipher.name, subtitle: cipher.subtitle)
            }
            state.selectedItemId = state.items.count == 1 ? state.items.first?.id : nil
            state.status = .pending
        } catch {
            // The request couldn't be fetched or unsealed, so no approval is offered.
            state.status = .failed
            services.errorReporter.log(error: error)
        }
    }

    /// Seals and sends the user's decision.
    ///
    /// - Parameter decision: The decision to send.
    ///
    private func submit(_ decision: ApprovalDecision) async {
        guard let openedRequest else { return }

        coordinator.showLoadingOverlay(title: Localizations.loading)
        do {
            let result = try await services.agentFillApprovalRepository.answer(
                state.approvalId,
                opened: openedRequest,
                decision: decision,
            )
            coordinator.hideLoadingOverlay()

            switch result {
            case .answered:
                let approved = if case .approved = decision { true } else { false }
                coordinator.navigate(to: .dismiss(DismissAction {
                    self.delegate?.agentFillApprovalAnswered(approved: approved)
                }))
            case .alreadyAnswered:
                state.status = .handled
            case .expired:
                state.status = .expired
            }
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
    private func verifyMasterPassword(_ password: String, thenSubmit decision: ApprovalDecision) async {
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
